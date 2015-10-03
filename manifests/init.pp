class omegaup (
	$root = '/opt/omegaup',
	$user = 'vagrant',
	$mysql_user = 'omegaup',
	$mysql_host = 'localhost',
	$services_ensure = running,
) {
	include omegaup::users
	include omegaup::scripts
	include omegaup::directories

	# Definitions
	define config_php($mysql_db) {
		file { $title:
			ensure  => 'file',
			content => template('omegaup/config.php.erb'),
			owner   => $user,
			group   => $user,
		}
	}

	# Packages
	package { ['git', 'curl', 'unzip', 'zip']:
		ensure  => installed,
	}

	package { 'hhvm':
		ensure  => installed,
		require => Apt::Source['hhvm'],
	}

	# Common
	file { '/var/www':
		ensure => 'directory',
	}
	exec { "submissions-directory":
		creates => '/var/lib/omegaup/submissions',
		command => '/tmp/mkhexdirs.sh /var/lib/omegaup/submissions www-data www-data',
		require => [File['/var/lib/omegaup'], File['/tmp/mkhexdirs.sh'],
		            User['www-data']],
	}

	# Repository
	file { $root:
		ensure => 'directory',
		owner  => $user,
	}
	vcsrepo { $root:
		ensure   => present,
		provider => git,
		source   => 'https://github.com/omegaup/omegaup.git',
		user     => $user,
		group    => $user,
		require  => File[$root],
	}
	file { "${root}/.git/hooks/pre-push":
		ensure  => 'link',
		target  => "${root}/stuff/git-hooks/pre-push",
		owner   => $user,
		group   => $user,
		require => Vcsrepo[$root],
	}

	# Web application
	file { ['/var/lib/omegaup/problems', '/var/lib/omegaup/problems.git']:
		ensure  => 'directory',
		owner   => 'www-data',
		group   => 'www-data',
		require => File['/var/lib/omegaup'],
	}
	file { '/var/log/omegaup/omegaup.log':
		ensure  => 'file',
		owner   => 'www-data',
		group   => 'www-data',
		require => File['/var/log/omegaup'],
	}
	file { '/var/www/omegaup.com':
		ensure  => 'link',
		target  => "${root}/frontend/www",
		require => [File['/var/www'], Vcsrepo[$root]],
	}
	file { ["${root}/frontend/www/img",
					"${root}/frontend/www/templates"]:
		ensure  => 'directory',
		owner   => 'www-data',
		group   => 'www-data',
		require => Vcsrepo[$root],
	}
	config_php { "${root}/frontend/server/config.php":
		mysql_db => 'omegaup',
		require => Vcsrepo[$root],
	}
	class { 'nginx':
		service_ensure => $services_ensure,
	}
	nginx::resource::vhost { 'localhost':
		ensure        => present,
		listen_port   => 80,
		www_root      => "${root}/frontend/www",
		index_files   => ['index.php', 'index.html'],
		include_files => ["${root}/frontend/server/nginx.rewrites"],
	}
	nginx::resource::location { 'php':
		ensure               => present,
		vhost                => 'localhost',
		www_root             => "${root}/frontend/www",
		location             => '~ \.(hh|php)$',
		fastcgi              => '127.0.0.1:9000',
		proxy                => undef,
		fastcgi_script       => undef,
		location_cfg_prepend => {
			fastcgi_param     => 'SCRIPT_FILENAME $document_root$fastcgi_script_name',
			fastcgi_index     => 'index.php',
			fastcgi_keep_conn => 'on',
		}
	}
	service { 'hhvm':
		ensure  => $services_ensure,
		enable  => true,
		require => Package['hhvm'],
	}
}
