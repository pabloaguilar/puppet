class omegaup::apt_sources::internal {
  # HHVM
  apt::source { 'hhvm':
    ensure => absent,
  }

  # Nginx
  apt::source { 'nginx':
    location => 'https://nginx.org/packages/mainline/ubuntu',
    repos    => 'nginx',
    key      => '573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62',
  }

  # omegaUp
  apt::ppa { 'ppa:omegaup/omegaup': }

  # NPM/yarn
  apt::source { 'nodesource':
    location => 'https://deb.nodesource.com/node_6.x',
    include  => {
      src    => false,
    },
    key      => {
      key_location => 'https://deb.nodesource.com/gpgkey/nodesource.gpg.key',
      id           => '9FD3B784BC1C6FC31A8A0A1C1655A0AB68576280',
    },
  }
  apt::source { 'yarn':
    location => 'https://dl.yarnpkg.com/debian/',
    release  => 'stable',
    include  => {
      src    => false,
    },
    key      => {
      key_location => 'https://dl.yarnpkg.com/debian/pubkey.gpg',
      id           => '72ECF46A56B4AD39C907BBB71646B01B86E50310',
    },
  }
}

# vim:expandtab ts=2 sw=2
