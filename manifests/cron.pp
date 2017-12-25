# The omegaUp cronjobs.
class omegaup::cron (
  $root = '/opt/omegaup',
) {
  include cron

  package { ['python3', 'python3-mysqldb']:
    ensure  => present,
  }

  cron::daily { 'aggregate_user_feedback':
    command => "${root}/stuff/cron/aggregate_user_feedback.py",
    minute  => 18,
    hour    => 10,
    require => Github[$root],
  }
  cron::hourly { 'update_user_rank':
    command => "${root}/stuff/cron/update_user_rank.py",
    minute  => 19,
    require => Github[$root],
  }
}

# vim:expandtab ts=2 sw=2

