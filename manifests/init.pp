class omegaup (
  $development_environment = false,
  $root = '/opt/omegaup',
  $user = 'vagrant',
  $grader_host = 'https://localhost:21680',
  $broadcaster_host = 'http://localhost:39613',
  $github_repo = 'omegaup/omegaup',
  $mysql_host = 'localhost',
  $mysql_user = 'omegaup',
  $mysql_password = undef,
  $services_ensure = running,
) {
  include omegaup::users
  include omegaup::scripts
  include omegaup::directories

  # Packages
  package { ['git', 'curl', 'unzip', 'zip']:
    ensure  => installed,
  }

  package { 'hhvm':
    ensure  => installed,
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
    ensure  => present,
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
  nginx::resource::vhost { 'omegaup':
    ensure            => present,
    listen_port       => 80,
    index_files       => ['index.php', 'index.html'],
    include_files     => ["${root}/frontend/server/nginx.rewrites"],
    error_pages       => {
      404 => '/404.html',
    },
    vhost_cfg_prepend => {
      root => "${root}/frontend/www",
    },
    require           => File['/etc/nginx/conf.d/default.conf'],
  }
  nginx::resource::location { 'php':
    ensure               => present,
    vhost                => 'omegaup',
    location             => '~ \.(hh|php)$',
    fastcgi              => '127.0.0.1:9000',
    proxy                => undef,
    fastcgi_script       => undef,
    location_cfg_prepend => {
      fastcgi_param            => 'SCRIPT_FILENAME $document_root$fastcgi_script_name',
      fastcgi_index            => 'index.php',
      fastcgi_keep_conn        => 'on',
      fastcgi_intercept_errors => 'on',
    },
  }
  nginx::resource::location { 'websockets':
    ensure               => present,
    vhost                => 'omegaup',
    location             => '^~ /api/contest/events/',
    proxy                => $broadcaster_host,
    proxy_set_header     => ['Upgrade $http_upgrade', 'Connection "upgrade"', 'Host $host'],
    location_cfg_prepend => {
      rewrite            => '^/api/contest/events/(.*) /$1 break',
    },
    location_cfg_append  => {
      proxy_http_version => '1.1',
    },
  }
  service { 'hhvm':
    ensure  => $services_ensure,
    enable  => true,
    require => Package['hhvm'],
  }

  # Database
  dbmigrate { $root:
    ensure                  => latest,
    development_environment => $development_environment,
    subscribe               => [Github[$root], Mysql::Db['omegaup'],
                                Mysql::Db['omegaup-test']],
  }

  # Development environment
  if $development_environment {
    class { '::omegaup::developer_environment':
      root           => $root,
      user           => $user,
      mysql_host     => $mysql_host,
      mysql_user     => $mysql_user,
      mysql_password => $mysql_password,
      require        => [Github[$root], Package['hhvm']],
    }
  }
}
