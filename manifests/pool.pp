# Managed a pool of php-fpm workers
#
# A pool of workers, in php-fpm speak, is simply a collection of PHP
# "workers" (the processes that actually process requests) which share a
# common configuration.  They all listen to the same socket, are run by the
# same user, and have a common set of rules about how many can be running at
# once.
#
# There are a number of options which control how instances of this type
# behave.
#
#  * `title` (string; *namevar*)
#
#     This name is rather significant; it ends up in a number of places,
#     including the default unix socket name for the pool.  Keep it
#     sensible.
#
#  * `master` (string; required)
#
#     Which `phpfpm::master` resource to associate this pool with.  If you
#     specify a master which doesn't exist, you'll get a Puppet compile
#     error.
#
#  * `listen` (string; optional; default `/etc/service/phpfpm-${master}/tmp/${name}.sock`)
#
#     Where to listen for requests to this pool.  If the value of this
#     attribute looks like a fully-qualified path, it will be interpreted as
#     a path to a unix socket (the default).  It can also be an
#     `<ipaddress>:<port>` pair, which instructs the pool to listen on the
#     specified IP address/port combo.  Otherwise, if it is a number it will
#     be taken as a port to listen on (on all interfaces).
#
#  * `max_workers` (integer; optional; default `10`)
#
#     How many concurrent workers *may* be spawned, before requests will
#     start to back up.  The default is *very* conservative, and real-world
#     sites should calculate a more appropriate value for this parameter.
#
#  * `strategy` (string; optional; default `"ondemand"`)
#
#     Which process-spawning strategy to employ in this pool.  There are
#     three possibly values for this attribute:
#
#     * `"ondemand"` (the default) -- In this strategy, a worker is spawned
#       to service a request if there is no idle worker in this pool, up to
#       a limit of `$max_workers` workers running at once.  To prevent
#       endless spawning of workers on a busy site, workers will remain
#       alive but idle for up to `process_idle_timeout`, before being
#       reaped.
#
#     * `"static"` -- Exactly `max_workers` workers will be spawned at
#       startup, and that is how many will be kept available.  New workers
#       will only be spawned in the pool if a worker dies for some reason
#       (segfault, etc).
#
#     * `"dynamic"` -- More-or-less, there will always be at least
#       `min_spare_workers` idle, at most `max_spare_workers` idle.  The
#       exception to this is that there will never be more than
#       `max_workers` in the pool at once.
#
#     The reason for making `"ondemand"` the default is that if you don't
#     end up using the pool much, this option is the most conservative of
#     system resources, at the cost of some startup time overhead.  For
#     heavy-use sites, `"dynamic"` is almost certainly the best approach.
#     I have no idea why you would ever want to use `"static"`.
#
#  * `min_spare_workers` (integer; optional; default `undef`)
#
#     How many workers to ensure are idle when using the `"dynamic"` worker
#     management strategy.  It is invalid to specify this attribute with any
#     other value for `strategy`.
#
#     This attribute should be set to as many requests as you think you
#     might receive in the time it takes to spawn a new worker.  If you set
#     this attribute too low, you'll get slower page load times during
#     periods of very rapid request rates.  Set too high, you'll consume
#     excessive memory due to wasted workers sitting around having smoko.
#
#  * `max_spare_workers` (integer; optional; default `undef`)
#
#     How many workers to allow to remain idle, rather than being reaped,
#     when using the `"dynamic"` worker management strategy.  It is invalid
#     to specify this attribute with any other value for `strategy`.
#
#     Setting this attribute to something higher than `min_spare_workers` is
#     useful in situations where you often get rapid "bursts" of requests. 
#     In this case, you'll save some CPU by not having to spawn new workers
#     for every little peak.  On the other hand, you'll be burning memory by
#     having them sitting around not doing anything.  Your choice.
#    
define phpfpm::pool(
	$master,
	$user,
	$listen            = "/etc/service/phpfpm-${master}/tmp/${name}.sock",
	$strategy          = "ondemand",
	$max_workers       = 10,
	$min_spare_workers = undef,
	$max_spare_workers = undef,
	$idle_timeout      = "30s",
) {
	$phpfpm_pool_name                 = $name
	$phpfpm_pool_user                 = $user
	$phpfpm_pool_listen               = $listen

	case $strategy {
		"static","dynamic","ondemand": {
			$phpfpm_pool_strategy             = $strategy
		}
		default: {
			fail("Invalid phpfpm::pool strategy: ${strategy}")
		}
	}
	
	if $strategy != "dynamic" {
		if $min_spare_workers {
			fail("min_spare_workers is not valid with strategy=\"${strategy}\"")
		}
		if $max_spare_workers {
			fail("max_spare_workers is not valid with strategy=\"${strategy}\"")
		}
	} else {
		$phpfpm_pool_min_spare_workers = $min_spare_workers
		$phpfpm_pool_max_spare_workers = $max_spare_workers
	}
	
	$phpfpm_pool_max_workers  = $max_workers
	$phpfpm_pool_idle_timeout = $idle_timeout
	
	file { "/etc/phpfpm/${master}/pool.d/${name}.conf":
		ensure  => file,
		content => template("phpfpm/etc/phpfpm/pool.conf"),
		mode    => 0444,
		owner   => "root",
		group   => "root",
		notify  => Phpfpm::Master[$master]
	}
}
		