class omegaup::grader (
	$root = '/opt/omegaup',
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
	file { "${root}/bin/omegaup.conf":
		ensure  => 'file',
		owner   => $user,
		group   => $user,
		mode    => '0644',
		content => template('omegaup/omegaup.conf.erb'),
		require => [Vcsrepo[$root]],
	}
	exec { "grade-directory":
		creates => '/var/lib/omegaup/grade',
		command => '/tmp/mkhexdirs.sh /var/lib/omegaup/grade omegaup omegaup',
		require => [File['/var/lib/omegaup'], File['/tmp/mkhexdirs.sh'],
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
								File["${root}/bin/omegaup.conf"],
								Package['libmysql-java'], Package['openjdk-8-jdk']],
	}
}
