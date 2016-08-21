class omegaup::database (
	$root_password,
	$password,
	$service_provider = 'systemd',
) {
	class { '::mysql::server':
		root_password    => $root_password,
		service_provider => $service_provider,
	}

	include '::mysql::server'

	mysql::db { 'omegaup':
		user     => 'omegaup',
		password => $password,
		host     => 'localhost',
		grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE'],
	}

	mysql::db { 'omegaup-test':
		user     => 'omegaup',
		password => $password,
		host     => 'localhost',
		grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'DROP'],
	}
}
