class omegaup::minijail {
  package { 'sudo':
    ensure  => present,
  }

  package { 'omegaup-minijail':
    ensure  => present,
  }

  file { '/etc/sudoers.d/minijail':
    ensure  => 'file',
    source  => 'puppet:///modules/omegaup/sudoers-minijail',
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    require => [User['omegaup'], Package['sudo']],
  }
}

# vim:expandtab ts=2 sw=2
