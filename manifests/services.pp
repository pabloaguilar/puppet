# The omegaUp services.
class omegaup::services {
  remote_file { '/var/lib/omegaup/omegaup-backend.tar.xz':
    source  => 'https://omegaup-dist.s3.amazonaws.com/omegaup-backend.tar.xz',
    mode    => 0644,
    owner   => 'root',
    group   => 'root',
    require => File['/var/lib/omegaup'],
  }

  exec { 'omegaup-backend':
    command     => '/bin/tar -xf /var/lib/omegaup/omegaup-backend.tar.xz -C /',
    user        => 'root',
    require     => File['/var/lib/omegaup/omegaup-backend.tar.xz'],
    refreshonly => true,
  }

  file { ['/usr/bin/omegaup-grader', '/usr/bin/omegaup-runner',
          '/usr/bin/omegaup-broadcaster']:
    require => Exec['omegaup-backend'],
  }
}

# vim:expandtab ts=2 sw=2
