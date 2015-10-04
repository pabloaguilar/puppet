class omegaup::grader (
	$user = 'vagrant',
	$embedded_runner = 'true',
	$keystore_password = 'omegaup',
	$mysql_user = 'omegaup',
	$mysql_db = 'omegaup',
	$mysql_host = 'localhost',
	$services_ensure = running,
) {
	include omegaup::java
	include omegaup::users
	include omegaup::scripts
	include omegaup::directories

	# Packages
	package { ['libmysql-java']:
		ensure  => installed,
	}
	file { '/var/log/omegaup/service.log':
		ensure  => 'file',
		owner   => 'omegaup',
		group   => 'omegaup',
		require => File['/var/log/omegaup'],
	}
	file { "/etc/omegaup/grader/omegaup.conf":
		ensure  => 'file',
		owner   => $user,
		group   => $user,
		mode    => '0644',
		content => template('omegaup/omegaup.conf.erb'),
		require => File['/etc/omegaup/grader'],
	}
	exec { "grade-directory":
		creates => '/var/lib/omegaup/grade',
		command => '/usr/bin/mkhexdirs /var/lib/omegaup/grade omegaup omegaup',
		require => [File['/var/lib/omegaup'], File['/usr/bin/mkhexdirs'],
		            User['omegaup']],
	}
	file { ['/var/lib/omegaup/compile', '/var/lib/omegaup/input']:
		ensure  => 'directory',
		owner   => 'omegaup',
		group   => 'omegaup',
		require => File['/var/lib/omegaup'],
	}
	file { '/etc/systemd/system/omegaup.service':
		ensure  => 'file',
		source  => "puppet:///modules/omegaup/omegaup.service",
		mode    => '0644',
	}
	service { 'omegaup':
		ensure  => $services_ensure,
		enable  => true,
		provider => 'systemd',
		require => [File['/etc/systemd/system/omegaup.service'],
								Exec['grade-directory'],
								File['/etc/omegaup/grader/omegaup.conf'],
								Package['libmysql-java'], Package['openjdk-8-jre']],
	}
}
