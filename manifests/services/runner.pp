# The omegaUp runner service.
class omegaup::services::runner (
  $services_ensure = running,
  $hostname = 'localhost',
  $grader_host = 'https://localhost:11302',
  $keystore_password = 'omegaup',
) {
  include omegaup::users

  # Configuration
  file { '/etc/omegaup/runner':
    ensure  => 'directory',
    require => File['/etc/omegaup'],
  }
  file { '/etc/omegaup/runner/config.json':
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    mode    => '0644',
    content => template('omegaup/runner/config.json.erb'),
    require => File['/etc/omegaup/runner'],
  }
  omegaup::certmanager::cert { '/etc/omegaup/runner/key.pem':
    hostname      => $hostname,
    password      => $keystore_password,
    owner         => 'omegaup',
    mode          => '0600',
    separate_cert => '/etc/omegaup/runner/certificate.pem',
    require       => [File['/etc/omegaup/runner'], User['omegaup']],
  }

  # Runtime files
  file { '/var/lib/omegaup/runner':
    ensure  => 'directory',
    owner   => 'omegaup',
    group   => 'omegaup',
    require => File['/var/lib/omegaup'],
  }
  file { ['/var/log/omegaup/runner.log',
          '/var/log/omegaup/runner.tracing.json']:
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    require => File['/var/log/omegaup'],
  }

  # Service
  file { '/etc/systemd/system/omegaup-runner.service':
    ensure => 'file',
    source => 'puppet:///modules/omegaup/omegaup-runner.service',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
  }
  service { 'omegaup-runner':
    ensure   => $services_ensure,
    enable   => true,
    provider => 'systemd',
    require  => [
      File[
        '/etc/systemd/system/omegaup-runner.service', '/usr/bin/omegaup-runner',
        '/etc/sudoers.d/minijail', '/var/lib/omegaup/runner',
        '/var/log/omegaup/runner.log', '/var/log/omegaup/runner.tracing.json',
        '/etc/omegaup/runner/config.json'
      ],
      Omegaup::Certmanager::Cert['/etc/omegaup/runner/key.pem'],
    ],
  }
}

# vim:expandtab ts=2 sw=2
