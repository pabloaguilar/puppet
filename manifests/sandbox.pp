hiera_include('classes')

file { '/etc/omegaup': ensure => 'directory' }

omegaup::certmanager::cert { '/etc/omegaup/frontend/certificate.pem':
  owner    => 'www-data',
  mode     => '0600',
  require  => [File['/etc/omegaup/frontend'], User['www-data']],
  hostname => hiera('omegaup_hostname'),
}
file { '/etc/omegaup/frontend':
  ensure  => 'directory',
  require => File['/etc/omegaup'],
}
class { '::omegaup':
  require => [Class['::omegaup::database'], Class['::omegaup::apt_sources']],
}

# vim:expandtab ts=2 sw=2
