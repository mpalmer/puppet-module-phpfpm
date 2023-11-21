class phpfpm::base {
	file {
		"/etc/phpfpm":
			ensure => directory,
			mode   => "0755",
			owner  => "root",
			group  => "root";
		"/etc/phpfpm/README":
			ensure => file,
			source => "puppet:///modules/phpfpm/etc/phpfpm/README",
			mode   => "0444",
			owner  => "root",
			group  => "root";
	}

	case $::operatingsystem {
		"Debian": {
			case $::lsbdistcodename {
				"jessie": {
					$pkg = "php5-fpm"
				}
				"buster": {
					$pkg = "php7.3-fpm"
				}
				default: {
					fail("No support for Debian ${::lsbdistcodename} in phpfpm::base.  Patches appreciated.")
				}
			}
		}
		"RedHat","CentOS": {
			$pkg = "php-fpm"
		}
		default: {
			fail("No support for your OS (${::operatingsystem}) in phpfpm::base.  Patches appreciated.")
		}
	}

	package { $pkg:
		ensure => present
	}
}
