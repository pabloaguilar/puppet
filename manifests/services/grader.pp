# The omegaUp grader service.
class omegaup::services::grader (
  $user = undef,
  $hostname = 'localhost',
  $embedded_runner = true,
  $broadcaster_host = 'https://localhost:32672',
  $frontend_host = 'http://localhost',
  $keystore_password = 'omegaup',
  $local_database = true,
  $mysql_db = 'omegaup',
  $mysql_host = 'localhost',
  $mysql_password = undef,
  $mysql_user = 'omegaup',
  $services_ensure = running,
) {
  include omegaup::users
  include omegaup::scripts
  include omegaup::directories

  # libinteractive
  package { 'openjdk-8-jre-headless':
    ensure => installed,
  }
  remote_file { '/usr/share/java/libinteractive.jar':
    source  => 'https://github.com/omegaup/libinteractive/releases/download/v2.0.19/libinteractive.jar',
    mode    => 0644,
    owner   => 'root',
    group   => 'root',
    require => Package['openjdk-8-jre-headless'],
  }

  # Configuration
  file { '/etc/omegaup/grader':
    ensure  => 'directory',
    require => File['/etc/omegaup'],
  }
  file { '/etc/omegaup/grader/config.json':
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    mode    => '0600',
    content => template('omegaup/grader/config.json.erb'),
    require => File['/etc/omegaup/grader'],
  }
  omegaup::certmanager::cert { '/etc/omegaup/grader/key.pem':
    hostname      => $hostname,
    password      => $keystore_password,
    owner         => 'omegaup',
    mode          => '0600',
    separate_cert => '/etc/omegaup/grader/certificate.pem',
    require       => [File['/etc/omegaup/grader'], User['omegaup']],
  }

  # Runtime files
  package { ['libhttp-parser2.1', 'libssh2-1']:
    ensure => installed,
  }
  file { ['/var/log/omegaup/service.log', '/var/log/omegaup/tracing.json']:
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    require => File['/var/log/omegaup'],
  }
  file { ['/var/lib/omegaup/input', '/var/lib/omegaup/cache',
          '/var/lib/omegaup/grade']:
    ensure  => 'directory',
    owner   => 'omegaup',
    group   => 'omegaup',
    require => File['/var/lib/omegaup'],
  }

  # Service
  file { '/etc/systemd/system/omegaup-grader.service':
    ensure => 'file',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    content => template('omegaup/grader/omegaup-grader.service.erb'),
  }
  service { 'omegaup-grader':
    ensure   => $services_ensure,
    enable   => true,
    provider => 'systemd',
    require  => [
      File[
        '/etc/systemd/system/omegaup-grader.service',
        '/var/lib/omegaup/input', '/var/lib/omegaup/cache',
        '/var/lib/omegaup/grade', '/var/log/omegaup/service.log',
        '/usr/share/java/libinteractive.jar',
        '/usr/bin/omegaup-grader',
        '/var/log/omegaup/tracing.json',
        '/etc/omegaup/grader/config.json'
      ],
      Omegaup::Certmanager::Cert['/etc/omegaup/grader/key.pem'],
      Package['libhttp-parser2.1', 'libssh2-1'],
    ],
  }
}

# vim:expandtab ts=2 sw=2
