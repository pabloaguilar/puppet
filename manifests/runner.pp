class { 'apt':
  update => {
    frequency => 'daily',
  },
}

# Pre-stage
stage { 'pre':
  before => Stage['main'],
}
class pre { # lint:ignore:autoloader_layout
  exec { 'stop_runner':
    command => '/bin/systemctl stop omegaup-runner',
    returns => [0, 1],
  }
}
class { 'pre':
  stage => 'pre',
}

class { '::omegaup::apt_sources': }
class { '::omegaup::runner': }

# vim:expandtab ts=2 sw=2
