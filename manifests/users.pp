# Creates users needed at runtime.
class omegaup::users {
  user { ['omegaup', 'www-data', 'omegaup-www', 'omegaup-deploy']: ensure => present }
}

# vim:expandtab ts=2 sw=2
