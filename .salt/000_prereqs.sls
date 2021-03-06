{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set php = salt['mc_php.settings']() %}

include:
  - makina-states.services.php.phpfpm_with_nginx

{% import "makina-states/services/php/macros.sls" as phpm with context %}
{{ phpm.toggle_ext('pgsql') }}
{{ phpm.toggle_ext('pdo_pgsql') }}
prepreqs-{{cfg.name}}:
  pkg.installed:
    - require_in:
      - mc_proxy: makina-php-pre-inst
    - pkgs:
      - unzip
      - xsltproc
      - curl
      - {{ php.packages.mysql }}
      - {{ php.packages.gd }}
      - {{ php.packages.cli }}
      - {{ php.packages.curl }}
      - {{ php.packages.ldap }}
      - {{ php.packages.dev }}
      - {{ php.packages.json }}
      - {{ php.packages.postgresql }}
      - {{ php.packages.redis }}
      - {{ php.packages.gmp }}
      - sqlite3
      - libsqlite3-dev
      - mysql-client
      - apache2-utils
      - autoconf
      - automake
      - build-essential
      - bzip2
      - gettext
      - git
      - groff
      - libbz2-dev
      - libcurl4-openssl-dev
      - libdb-dev
      - libgdbm-dev
      - libreadline-dev
      - libfreetype6-dev
      - libsigc++-2.0-dev
      - libsqlite0-dev
      - libsqlite3-dev
      - libtiff5
      - libtiff5-dev
      - libwebp5
      - libwebp-dev
      - libssl-dev
      - libtool
      - libxml2-dev
      - libxslt1-dev
      - libopenjpeg-dev
      - m4
      - man-db
      - pkg-config
      - poppler-utils
      - python-dev
      - python-imaging
      - python-setuptools
      - tcl8.4
      - tcl8.4-dev
      - tcl8.5
      - tcl8.5-dev
      - tk8.5-dev
      - wv
      - zlib1g-dev


prepreqs-{{cfg.name}}-extra-php7-only-php-mbstring:
  pkg.installed:
    - require_in:
      - mc_proxy: makina-php-pre-inst
    - require:
      - pkg: prepreqs-{{cfg.name}}
    - pkgs:
      # this will only work with php7, before it was in the php main package
      - php-mbstring
    - onlyif:
      - apt-cache search php-mbstring|grep mbstring


{#
This produce the default layout

  /project     : sources
    bin/       : binaries
    www/       : docroot
    www/sites/default  link --> ../data/var/sites/default
    lib/       : extra libs
    var        link --> ../data/var
    tmp        link --> ../data/var/tmp

  /data    : persistent data
    bin    link --> ../project/bin
    www    link --> ../project/www
    lib    link --> ../project/lib
    var/   : runtime files (sockets, logs, session, tempfiles)
    var/sites/default : default site files and settings

#}

{{cfg.name}}-dirs:
  file.directory:
    - makedirs: true
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - mode: 770
    - watch:
      - pkg: prepreqs-{{cfg.name}}
    - names:
      - {{cfg.project_root}}/lib
      - {{cfg.project_root}}/bin
      - {{cfg.project_root}}/www
      - {{cfg.data_root}}/var
      - {{cfg.data_root}}/var/sites
      - {{cfg.data_root}}/var/sites/default/files
      - {{cfg.data_root}}/var/log
      - {{cfg.data_root}}/var/tmp
      - {{cfg.data_root}}/var/run
      - {{cfg.data_root}}/var/private

{% for d in ['lib', 'bin', 'www'] %}
{{cfg.name}}-dirs{{d}}:
  file.symlink:
    - target: {{cfg.project_root}}/{{d}}
    - name: {{cfg.data_root}}/{{d}}
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - watch:
      - file: {{cfg.name}}-dirs
    - watch_in:
      - mc_proxy: makina-apache-pre-inst
      - mc_proxy: makina-php-pre-inst
      - mc_proxy: nginx-pre-install-hook
{% endfor %}
{{cfg.name}}-l-dirs-sites:
  file.symlink:
    - name: {{cfg.project_root}}/www/sites/default
    - target: {{cfg.data_root}}/var/sites/default
    - makedirs: true
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - watch:
      - file: {{cfg.name}}-dirs
    - watch_in:
      - mc_proxy: makina-apache-pre-inst
      - mc_proxy: makina-php-pre-inst
      - mc_proxy: nginx-pre-install-hook

{% for d in ['var'] %}
{{cfg.name}}-l-dirs{{d}}:
  file.symlink:
    - name: {{cfg.project_root}}/{{d}}
    - target: {{cfg.data_root}}/{{d}}
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - watch:
      - file: {{cfg.name}}-dirs
    - watch_in:
      - mc_proxy: makina-apache-pre-inst
      - mc_proxy: makina-php-pre-inst
      - mc_proxy: nginx-pre-install-hook
{% endfor %}

{% for d in ['log', 'private', 'tmp'] %}
{{cfg.name}}-l-var-dirs{{d}}:
  file.symlink:
    - name: {{cfg.project_root}}/{{d}}
    - target: {{cfg.data_root}}/var/{{d}}
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - watch:
      - file: {{cfg.name}}-dirs
    - watch_in:
      - mc_proxy: makina-apache-pre-inst
      - mc_proxy: makina-php-pre-inst
      - mc_proxy: nginx-pre-install-hook
{% endfor %}
