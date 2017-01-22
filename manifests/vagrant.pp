class { '::omegaup::apt_sources': }

class { '::omegaup::database':
  root_password => $mysql_password,
  password      => $mysql_password,
}

class { '::omegaup::certmanager': }
file { '/etc/omegaup': ensure => 'directory' }

class { '::omegaup::minijail': }
class { '::omegaup::services::grader': }
class { '::omegaup::services::runner': }
class { '::omegaup::services::broadcaster': }

omegaup::certmanager::cert { '/etc/omegaup/frontend/certificate.pem':
  hostname => 'localhost',
  owner    => 'www-data',
  mode     => '0600',
  require  => [File['/etc/omegaup/frontend'], User['www-data']],
}
file { '/etc/omegaup/frontend':
  ensure  => 'directory',
  require => File['/etc/omegaup'],
}
class { '::omegaup':
  development_environment => true,
  mysql_password          => $mysql_password,
  require                 => [Class['::omegaup::database'],
                              Class['::omegaup::apt_sources']],
}

# vim:expandtab ts=2 sw=2
