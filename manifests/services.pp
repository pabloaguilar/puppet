# The omegaUp services.
class omegaup::services {
  remote_file { '/var/lib/omegaup/omegaup-backend.tar.xz':
    url      => 'https://omegaup-dist.s3.amazonaws.com/omegaup-backend.tar.xz',
    sha1hash => 'd438295a9f4e2f378f5d40cfa7830819914dc22e',
    mode     => 644,
    owner    => 'root',
    group    => 'root',
    notify   => Exec['unlink omegaup-backend'],
    require  => File['/var/lib/omegaup'],
  }

  exec { 'unlink omegaup-backend':
    command     => '/bin/rm -f /usr/bin/omegaup-grader /usr/bin/omegaup-runner /usr/bin/omegaup-broadcaster',
    user        => 'root',
    notify      => Exec['omegaup-backend'],
    refreshonly => true,
  }

  exec { 'omegaup-backend':
    command     => '/bin/tar -xf /var/lib/omegaup/omegaup-backend.tar.xz -C /',
    user        => 'root',
    notify      => File[
      '/usr/bin/omegaup-grader',
      '/usr/bin/omegaup-runner',
      '/usr/bin/omegaup-broadcaster'
    ],
    refreshonly => true,
  }

  file { ['/usr/bin/omegaup-grader', '/usr/bin/omegaup-runner',
          '/usr/bin/omegaup-broadcaster']:
    require => Exec['omegaup-backend'],
  }
}

# vim:expandtab ts=2 sw=2
