class omegaup::developer_environment (
  $root,
  $user,
  $mysql_host,
  $mysql_user,
  $mysql_password,
) {
  # Packages
  package { [ 'vim', 'openssh-client', 'gcc', 'g++', 'python3',
              'clang-format-3.7', 'python-pip', 'python3-six', 'python-six',
              'silversearcher-ag', 'ca-certificates', 'meld', 'vim-gtk',
              'yarn', 'nodejs' ]:
    ensure  => present,
  }
  php::extension { 'PHP_CodeSniffer':
    ensure   => '2.9.1',
    sapi     => 'none',
    provider => 'pear',
  }
  Anchor['php::begin'] -> class { '::php::phpunit':
    source      => 'https://phar.phpunit.de/phpunit-5.3.4.phar',
    auto_update => false,
    path        => '/usr/bin/phpunit',
  } -> Anchor['php::end']
  package { 'https://github.com/google/closure-linter/zipball/master':
    ensure   => present,
    provider => 'pip',
  }

  # Test setup
  config_php { 'test settings':
    ensure   => present,
    settings => {
      'OMEGAUP_DB_USER'     => $mysql_user,
      'OMEGAUP_DB_HOST'     => $mysql_host,
      'OMEGAUP_DB_PASS'     => $mysql_password,
      'OMEGAUP_DB_NAME'     => 'omegaup-test',
      'OMEGAUP_SSLCERT_URL' => '/etc/omegaup/frontend/certificate.pem',
      'OMEGAUP_CACERT_URL'  => '/etc/omegaup/frontend/certificate.pem',
    },
    path     => "${root}/frontend/tests/test_config.php",
    owner    =>  $user,
    group    =>  $user,
  }
  config_php { 'developer settings':
    ensure   => present,
    settings => {
      'OMEGAUP_DEVELOPMENT_MODE' => 'true', # lint:ignore:quoted_booleans
    },
    path     => "${root}/frontend/server/config.php",
    require  => Config_php['default settings'],
  }
  config_php { 'experiments schools':
    ensure   => present,
    settings => {
      'EXPERIMENT_SCHOOLS' => 'true', # lint:ignore:quoted_booleans
    },
    path     => "${root}/frontend/server/config.php",
    require  => Config_php['default settings'],
  }
  file { "${root}/frontend/tests/controllers/omegaup.log":
    ensure => 'file',
    owner  => $user,
    group  => $user,
  }
  file { ["${root}/frontend/tests/controllers/problems",
      "${root}/frontend/tests/controllers/submissions"]:
    ensure => 'directory',
    owner  => $user,
    group  => $user,
  }
}

# vim:expandtab ts=2 sw=2
