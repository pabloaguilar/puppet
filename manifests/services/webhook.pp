# The omegaUp webhook service.
class omegaup::services::webhook (
  $services_ensure = running,
  $webhook_secret = undef,
  $oauth_token = undef,
) {
  include omegaup::users

  # Configuration
  file { '/etc/omegaup/webhook':
    ensure  => 'directory',
    require => File['/etc/omegaup'],
  }
  file { '/etc/omegaup/webhook/config.json':
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    mode    => '0644',
    content => template('omegaup/webhook/config.json.erb'),
    require => File['/etc/omegaup/webhook'],
  }
  file { '/etc/sudoers.d/omegaup-deploy':
    ensure  => 'file',
    source  => 'puppet:///modules/omegaup/sudoers-omegaup-deploy',
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    require => [User['omegaup-deploy'], Package['sudo']],
  }
  file { '/usr/bin/omegaup-webhook':
    ensure  => 'file',
    source  => 'puppet:///modules/omegaup/omegaup-webhook',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }
  file { '/usr/bin/omegaup-deploy-latest':
    ensure  => 'file',
    source  => 'puppet:///modules/omegaup/omegaup-deploy-latest',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }
  file { '/var/lib/omegaup/webhook':
    ensure  => 'directory',
    owner   => 'omegaup-deploy',
    group   => 'omegaup-deploy',
    mode    => '0755',
    require => [User['omegaup-deploy'], File['/var/lib/omegaup']],
  }

  # Service
  file { '/etc/systemd/system/omegaup-webhook.service':
    ensure  => 'file',
    source  => 'puppet:///modules/omegaup/omegaup-webhook.service',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => File['/usr/bin/omegaup-webhook'],
  }
  service { 'omegaup-webhook':
    ensure    => $services_ensure,
    enable    => true,
    provider  => 'systemd',
    subscribe => File['/usr/bin/omegaup-webhook',
                      '/etc/omegaup/webhook/config.json'],
    require   => File['/etc/systemd/system/omegaup-webhook.service',
                      '/usr/bin/omegaup-webhook',
                      '/usr/bin/omegaup-deploy-latest',
                      '/etc/sudoers.d/omegaup-deploy',
                      '/etc/omegaup/webhook/config.json',
                      '/var/lib/omegaup/webhook'],
  }
}

# vim:expandtab ts=2 sw=2
