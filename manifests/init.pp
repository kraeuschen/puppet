#exec { 'apt-get update':
#    command => '/usr/bin/apt-get update',
#}

  if (!defined(Group['jenkins'])) {
    group {
      'jenkins' :
        ensure => present;
    }
  }

  if (!defined(User['jenkins'])) {
    user {
      'jenkins' :
        ensure => present;
    }
  }

#include java
#include pear
#include phpqatools
#include jenkins
include jenkins4php
