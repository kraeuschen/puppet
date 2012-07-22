# Class: java
#
# This module manages java
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]
class java {
	package { "openjdk-6-jre":
		ensure => installed
	}
}
