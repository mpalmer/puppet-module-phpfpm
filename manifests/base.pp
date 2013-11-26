class phpfpm::base {
	file {
		"/etc/phpfpm":
			ensure => directory,
			mode   => 0755,
			owner  => "root",
			group  => "root";
		"/etc/phpfpm/README":
			ensure => file,
			source => "puppet:///modules/phpfpm/etc/phpfpm/README",
			mode   => 0444,
			owner  => "root",
			group  => "root";
	}
}
