class omegaup::apt_sources {
  # Stages
  stage { 'init':
    before => Stage['main'],
  }

  # Packages
  class { 'apt':
    update => {
      frequency => 'daily',
    },
    stage  => init,
  }

  include apt

  Apt::Source <| |> ~> Class['apt::update']

  class { '::omegaup::apt_sources::internal':
    stage => init,
  }
}
