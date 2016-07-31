class omegaup::apt_sources (
	$distribution = 'wily',
) {
	# Stages
	stage { 'init':
		before => Stage['main'],
	}

	# Packages
	class { 'apt':
		update => {
			frequency => 'daily',
		},
		stage => init,
	}

	include apt

	Apt::Source <| |> ~> Class['apt::update']

	class { '::omegaup::apt_sources::internal':
		stage => init,
		distribution => $distribution,
	}
}

class omegaup::apt_sources::internal (
	$distribution = 'wily',
) {
	apt::pin { $distribution: priority => 700 }

	# HHVM
	apt::source { 'hhvm':
		location    => 'http://dl.hhvm.com/ubuntu',
		include     => {
			src       => false,
		},
		key         => {
			server    => 'hkp://keyserver.ubuntu.com:80',
			id        => '0x36aef64d0207e7eee352d4875a16e7281be7a449',
		},
	}

	# omegaUp
	apt::ppa { 'ppa:omegaup/omegaup': }
}
