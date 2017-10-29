class omegaup (
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
  $services_ensure = running,
  $ssl = false,
) {
  include omegaup::users
  include omegaup::scripts
  include omegaup::directories

  # Packages
  package { ['git', 'curl', 'unzip', 'zip', 'sudo']:
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
    settings => {
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
    },
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
      ssl_ciphers          => 'HIGH:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!SRP:!DSS',
      ssl_dhparam          => "/etc/ssl/private/${hostname}.dhparam",
      index_files          => ['index.php', 'index.html'],
      include_files        => ["${root}/frontend/server/nginx.rewrites"],
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
      fastcgi_param            => 'SCRIPT_FILENAME $document_root$fastcgi_script_name',
      fastcgi_index            => 'index.php',
      fastcgi_keep_conn        => 'on',
    },
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
        'listen'       => '/run/php/php7.0-fpm.sock',
        'listen_owner' => 'www-data',
        'listen_group' => 'www-data',
      },
    },
    extensions   => {
      curl         => {
        provider   => 'apt',
      },
      mbstring     => {
        provider   => 'apt',
      },
      mcrypt       => {
        provider   => 'apt',
      },
      mysqli       => {
        provider   => 'none',
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
