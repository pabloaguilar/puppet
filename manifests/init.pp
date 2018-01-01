class omegaup (
  $additional_php_config_settings = {},
  $development_environment = false,
  $root = '/opt/omegaup',
  $user = undef,
  $local_database = false,
  $grader_host = 'https://localhost:21680',
  $hostname = 'localhost',
  $broadcaster_host = 'http://localhost:39613',
  $github_repo = 'omegaup/omegaup',
  $github_ensure = present,
  $mysql_host = 'localhost',
  $mysql_password = undef,
  $mysql_user = 'omegaup',
  $php_max_children = 36,
  $php_max_requests = 500,
  $services_ensure = running,
  $ssl = false,
) {
  include omegaup::users
  include omegaup::scripts
  include omegaup::directories

  # Packages
  package { ['git', 'curl', 'unzip', 'zip', 'sudo', 'python3-pip']:
    ensure  => installed,
  }

  package { 'hhvm':
    ensure  => absent,
  }

  # Common
  file { '/var/www':
    ensure => 'directory',
  }
  exec { 'submissions-directory':
    creates => '/var/lib/omegaup/submissions',
    command => '/usr/bin/mkhexdirs /var/lib/omegaup/submissions www-data www-data',
    require => [File['/var/lib/omegaup'], File['/usr/bin/mkhexdirs'],
                User['www-data']],
  }
  exec { 'systemctl daemon-reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  # Repository
  file { $root:
    ensure => 'directory',
    owner  => $user,
    group  => $user,
  }
  github { $root:
    ensure  => $github_ensure,
    repo    => $github_repo,
    owner   => $user,
    group   => $user,
    require => [File[$root], Package['git']],
  }
  file { "${root}/.git/hooks/pre-push":
    ensure  => 'link',
    target  => "${root}/stuff/git-hooks/pre-push",
    owner   => $user,
    group   => $user,
    require => Github[$root],
  }

  # Web application
  file { ['/var/lib/omegaup/problems', '/var/lib/omegaup/problems.git']:
    ensure  => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    require => File['/var/lib/omegaup'],
  }
  file { '/var/log/omegaup/omegaup.log':
    ensure  => 'file',
    owner   => 'www-data',
    group   => 'www-data',
    require => File['/var/log/omegaup'],
  }
  file { '/var/log/omegaup/csp.log':
    ensure  => 'file',
    owner   => 'www-data',
    group   => 'www-data',
    require => File['/var/log/omegaup'],
  }
  file { '/var/www/omegaup.com':
    ensure  => 'link',
    target  => "${root}/frontend/www",
    require => [File['/var/www'], Github[$root]],
  }
  file { ["${root}/frontend/www/img",
          "${root}/frontend/www/templates"]:
    ensure  => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    require => Github[$root],
  }
  config_php { 'default settings':
    ensure   => present,
    settings => merge({
      'OMEGAUP_DB_USER'                  => $mysql_user,
      'OMEGAUP_DB_HOST'                  => $mysql_host,
      'OMEGAUP_DB_PASS'                  => $mysql_password,
      'OMEGAUP_DB_NAME'                  => 'omegaup',
      'OMEGAUP_SSLCERT_URL'              => '/etc/omegaup/frontend/certificate.pem',
      'OMEGAUP_CACERT_URL'               => '/etc/omegaup/frontend/certificate.pem',
      'OMEGAUP_GRADER_URL'               => "${grader_host}/run/grade/",
      'OMEGAUP_GRADER_BROADCAST_URL'     => "${grader_host}/broadcast/",
      'OMEGAUP_GRADER_RELOAD_CONFIG_URL' => "${grader_host}/reload-config/",
      'OMEGAUP_GRADER_STATUS_URL'        => "${grader_host}/grader/status/",
    }, $additional_php_config_settings),
    path     => "${root}/frontend/server/config.php",
    owner    => $user,
    group    => $user,
    require  => Github[$root],
  }
  class { 'nginx':
    service_ensure => $services_ensure,
    manage_repo    => false,
  }
  file { '/etc/nginx/conf.d/default.conf':
    ensure  => absent,
    require => Package['nginx'],
  }
  $nginx_server = $ssl ? {
    true  => "${hostname}-ssl",
    false => $hostname,
  }
  if $ssl {
    exec { "${hostname}.dhparam":
      command => "/usr/bin/openssl dhparam -out /etc/ssl/private/${hostname}.dhparam 2048",
      user    => 'root',
      creates => "/etc/ssl/private/${hostname}.dhparam",
    }
    nginx::resource::server { $hostname:
      ensure            => present,
      index_files       => [],
      listen_port       => 80,
      rewrite_rules     => ["^ https://${hostname}\$request_uri permanent"],
      server_name       => [$hostname],
      require           => File['/etc/nginx/conf.d/default.conf'],
    }
    nginx::resource::server { "${hostname}-ssl":
      ensure               => present,
      listen_port          => 443,
      listen_options       => 'http2 default_server',
      server_name          => [$hostname],
      ssl                  => true,
      ssl_cert             => "/etc/letsencrypt/live/${hostname}/fullchain.pem",
      ssl_key              => "/etc/letsencrypt/live/${hostname}/privkey.pem",
      ssl_ciphers          => 'EECDH+AESGCM:EDH+AESGCM:ECDHE-RSA-AES128-GCM-SHA256:AES256+EECDH:DHE-RSA-AES128-GCM-SHA256:AES256+EDH:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK:!RC4',
      ssl_protocols        => 'TLSv1.2 TLSv1.1 TLSv1',
      ssl_dhparam          => "/etc/ssl/private/${hostname}.dhparam",
      index_files          => ['index.php', 'index.html'],
      include_files        => ["${root}/frontend/server/nginx.rewrites"],
      gzip_types           => 'application/javascript text/html text/css image/x-icon',
      error_pages          => {
        404 => '/404.html',
      },
      client_max_body_size => '100m',
      server_cfg_prepend   => {
        resolver                => '208.67.222.222 208.67.220.220 valid=300s',
        resolver_timeout        => '5s',
        root                    => "${root}/frontend/www",
        ssl_stapling            => 'on',
        ssl_stapling_verify     => 'on',
        gzip                    => 'on',
        expires                 => '7d',
        ssl_trusted_certificate => "/etc/letsencrypt/live/${hostname}/fullchain.pem",
      },
      require              => [File['/etc/nginx/conf.d/default.conf'],
                               Exec["${hostname}.dhparam"]],
    }
  } else {
    nginx::resource::server { $hostname:
      ensure               => present,
      server_name          => [$hostname],
      listen_port          => 80,
      index_files          => ['index.php', 'index.html'],
      include_files        => ["${root}/frontend/server/nginx.rewrites"],
      error_pages          => {
        404 => '/404.html',
      },
      client_max_body_size => '100m',
      server_cfg_prepend   => {
        root => "${root}/frontend/www",
      },
      require              => File['/etc/nginx/conf.d/default.conf'],
    }
    nginx::resource::server { "${hostname}-ssl":
      ensure            => absent,
    }
  }
  nginx::resource::location { 'php':
    ensure               => present,
    server               => $nginx_server,
    ssl                  => $ssl,
    ssl_only             => $ssl,
    location             => '~ \.php$',
    fastcgi              => 'unix:/run/php/php7.0-fpm.sock',
    proxy                => undef,
    fastcgi_script       => undef,
    location_cfg_prepend => {
      gzip                     => 'off',
      expires                  => '-1',
      fastcgi_param            => 'SCRIPT_FILENAME $document_root$fastcgi_script_name',
      fastcgi_index            => 'index.php',
      fastcgi_keep_conn        => 'on',
    },
  }
  exec { 'awscli':
    command  => '/usr/bin/pip3 install --system --upgrade awscli',
    creates  => '/usr/local/bin/aws',
    require  => Package['python3-pip'],
  }

  # Documentation
  file { '/var/www/omegaup.com/docs':
    ensure => 'directory',
    require => [
      File['/var/www/omegaup.com'],
    ],
  }
  remote_file { '/var/lib/omegaup/cppreference.tar.gz':
    url      => 'http://upload.cppreference.com/mwiki/images/3/37/html_book_20170409.tar.gz',
    sha1hash => '4708fb287544e8cfd9d6be56264384016976df94',
    mode     => 644,
    owner    => 'root',
    group    => 'root',
    notify   => Exec['extract-cppreference'],
    require  => File['/var/lib/omegaup'],
  }
  file { '/var/www/omegaup.com/docs/cpp':
    ensure => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    require => [
      User['www-data'],
      File['/var/www/omegaup.com/docs'],
    ],
  }
  exec { 'extract-cppreference':
    command     => '/bin/tar -xf /var/lib/omegaup/cppreference.tar.gz --group=omegaup-www --owner=omegaup-www --strip-components=1 --directory=/var/www/omegaup.com/docs/cpp reference',
    user        => 'root',
    require     => [
      Remote_File['/var/lib/omegaup/cppreference.tar.gz'],
      File['/var/www/omegaup.com/docs/cpp'],
      User['www-data'],
    ],
    refreshonly => true,
  }
  remote_file { '/var/lib/omegaup/freepascal-doc.tar.gz':
    url      => 'ftp://ftp.hu.freepascal.org/pub/fpc/dist/3.0.2/docs/doc-html.tar.gz',
    sha1hash => 'b9b9dc3d624d3dd2699e008aa10bd0181d2bda77',
    mode     => 644,
    owner    => 'root',
    group    => 'root',
    notify   => Exec['extract-freepascal-doc'],
    require  => File['/var/lib/omegaup'],
  }
  file { '/var/www/omegaup.com/docs/pas':
    ensure => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    require => [
      User['www-data'],
      File['/var/www/omegaup.com/docs'],
    ],
  }
  file { '/var/www/omegaup.com/docs/pas/en':
    ensure => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    require => [
      User['www-data'],
      File['/var/www/omegaup.com/docs/pas'],
    ],
  }
  exec { 'extract-freepascal-doc':
    command     => '/bin/tar -xf /var/lib/omegaup/freepascal-doc.tar.gz --group=omegaup-www --owner=omegaup-www --strip-components=1 --directory=/var/www/omegaup.com/docs/pas/en doc',
    user        => 'root',
    require     => [
      Remote_File['/var/lib/omegaup/freepascal-doc.tar.gz'],
      File['/var/www/omegaup.com/docs/pas/en'],
      User['www-data'],
    ],
    refreshonly => true,
  }
  file { '/var/www/omegaup.com/docs/pas/en/index.html':
    ensure  => 'link',
    target  => 'fpctoc.html',
    require => Exec['extract-freepascal-doc'],
  }

  # PHP
  class { '::php':
    ensure       => latest,
    manage_repos => false,
    fpm          => true,
    settings     => {
      'PHP/post_max_size'       => '200M',
      'PHP/upload_max_filesize' => '200M',
    },
    fpm_pools     => {
      'www'       => {
        'listen'          => '/run/php/php7.0-fpm.sock',
        'listen_owner'    => 'www-data',
        'listen_group'    => 'www-data',
        'pm_max_children' => $php_max_children,
        'pm_max_requests' => $php_max_requests,
      },
    },
    extensions   => {
      apcu         => {
        provider       => 'apt',
        package_prefix => 'php-',
        settings       => {
          'apc.enable_cli' => 1,
        },
      },
      curl         => {
        provider   => 'apt',
      },
      mbstring     => {
        provider   => 'apt',
      },
      mcrypt       => {
        provider   => 'apt',
      },
      mysql        => {
        provider   => 'apt',
        so_name    => 'mysqli',
      },
      zip          => {
        provider   => 'apt',
      },
    },
  }

  # Database
  if $local_database {
    dbmigrate { $root:
      ensure                  => latest,
      development_environment => $development_environment,
      subscribe               => [Github[$root], Mysql::Db['omegaup']],
    }

    Mysql::Db['omegaup'] -> Class['nginx']

    if $development_environment {
      Mysql::Db['omegaup-test'] ~> Dbmigrate[$root]
    }
  }

  # Development environment
  if $development_environment {
    class { '::omegaup::developer_environment':
      root           => $root,
      user           => $user,
      mysql_host     => $mysql_host,
      mysql_user     => $mysql_user,
      mysql_password => $mysql_password,
      require        => [Github[$root]],
    }
  }

  # Log management
  package { 'logrotate':
    ensure => installed,
  }
  file { '/etc/logrotate.d/omegaup':
    ensure  => 'file',
    source  => 'puppet:///modules/omegaup/omegaup.logrotate',
    mode    => 0644,
    owner   => 'root',
    group   => 'root',
    require => Package['logrotate'],
  }
}

# vim:expandtab ts=2 sw=2
