class omegaup::apt_sources::internal {
  # HHVM
  apt::source { 'hhvm':
    location => 'http://dl.hhvm.com/ubuntu',
    include  => {
      src    => false,
    },
    key      => {
      server => 'hkp://keyserver.ubuntu.com:80',
      id     => '0x36aef64d0207e7eee352d4875a16e7281be7a449',
    },
  }

  # Nginx
  apt::source { 'nginx':
    location => 'https://nginx.org/packages/mainline/ubuntu',
    repos    => 'nginx',
    key      => '573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62',
  }

  # omegaUp
  if $::lsbdistcodename != 'trusty' {
    # minijail is not supported on trusty.
    apt::ppa { 'ppa:omegaup/omegaup': }
  }
}
