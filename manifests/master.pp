# Configure a php-fpm master server.
#
# A php-fpm "master" is the long-lived process that starts and stops PHP
# workers as required to service requests.  Most systems will only need one
# of these (since a single master can control any number of pools of
# workers), but this type supports multiple masters on one system if
# required, by spawning each as a daemontools-managed service.
#
# The vast majority of the interesting configuration happens in the
# individual pools (which are configured with the `phpfpm::pool` type), but
# there are a few attributes you can set at the global level:
#
#  * `title` (string; *namevar*)
#
#     The name of the master.  This is used in a number of places,
#     specifically in the name of the daemontools service
#     (`phpfpm-${title}`) as well as the directory which contains all of the
#     configuration (`/etc/phpfpm/${title}`).
#
#  * `log_level` (string; optional; default `"notice"`)
#
#     The verbosity of the php-fpm logs.  All logs will be sent to `stderr`,
#     which means they'll get caught by daemontools and accessable in the
#     standard location (`/etc/service/phpfpm-${title}/log/logs/current`).
#
#  * `max_workers` (integer; optional; default: `10`)
#
#     This is the absolute maximum number of PHP "workers" (the processes
#     which actually process requests and return responses) which will be
#     spawned by this master.  Note that this is the maximum number of
#     requests for dynamic content which can be processed simultaneously;
#     thus, setting this number too low (such as the default, which is a
#     deliberately conservative figure) will have an adverse impact on
#     response times on busy sites.
#
#     This is meant to be a "safety valve" of sorts against a huge amount of
#     incoming traffic; you should set this to some rather high value which
#     won't interfere with normal operation, but which won't allow your
#     machine to be ground into dust by an influx of traffic.
#
#  * `php_ini` (string; optional; default `undef`)
#
#     If set to a non-`undef` value, this attribute is taken as the
#     fully-qualified path to a `php.ini` file to use as the default
#     configuration for all pools defined by this master.  Left as the
#     default, the pool will use the PHP build's own `php.ini`
#     configuration.
#
define phpfpm::master(
	$log_level   = "notice",
	$max_workers = 10,
	$php_ini     = undef
) {
	include phpfpm::base
	
	# Template variables
	$phpfpm_master_name        = $name
	$phpfpm_master_log_level   = $log_level
	$phpfpm_master_max_workers = $max_workers
	
	file {
		"/etc/phpfpm/${name}":
			ensure  => directory,
			mode    => "0755",
			owner   => "root",
			group   => "root";
		"/etc/phpfpm/${name}/pool.d":
			ensure  => directory,
			mode    => "0755",
			owner   => "root",
			group   => "root",
			purge   => true,
			recurse => true,
			notify  => Exec["phpfpm/master/${name}:reload"];
		"/etc/phpfpm/${name}/master.conf":
			ensure  => file,
			content => template("phpfpm/etc/phpfpm/master.conf"),
			mode    => "0444",
			owner   => "root",
			group   => "root",
			notify  => Exec["phpfpm/master/${name}:reload"];
		"/etc/service/phpfpm-${name}/tmp":
			ensure  => directory,
			mode    => "0710",
			owner   => "root",
			group   => "www-data",
			require => Daemontools::Service["phpfpm-${name}"];
	}

	exec { "phpfpm/master/${name}:reload":
		command     => "/usr/bin/svc -2 /etc/service/phpfpm-${name}",
		refreshonly => true;
	}
	
	case $::operatingsystem {
		"Debian": {
			$phpfpm_master_command = "/usr/sbin/php5-fpm"
		}
		"RedHat","CentOS": {
			$phpfpm_master_command = "/usr/sbin/php-fpm"
		}
		default: {
			fail("phpfpm::master does not know about your operatingsystem (${::operatingsystem}).  Please submit a patch.")
		}
	}
	
	if $php_ini {
		$php_ini_opt = " --php-ini ${php_ini}"
	} else {
		$php_ini_opt = ""
	}
	
	# The master daemon itself needs to run as root, so it can drop privs to
	# individual users as required for each pool
	daemontools::service { "phpfpm-${name}":
		command => "${phpfpm_master_command}${php_ini_opt} -y /etc/phpfpm/${name}/master.conf",
		user    => "root",
		setuid  => false
	}
}
