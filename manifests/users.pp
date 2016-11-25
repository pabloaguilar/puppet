# Creates users needed at runtime.
class omegaup::users {
  user { ['omegaup', 'www-data']: ensure => present }
}
