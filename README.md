Manage a php-fpm installation without pain and suffering.

This module allows you to setup a php-fpm master (running under daemontools,
because that's how I roll), and then configure pools to run under that
master.

To get started, instantiate a `phpfpm::master` resource.  In here, you can
(but don't *have* to) set a variety of global parameters, such as the
absolute maximum number of workers, the log level, and so on.

You can then define whichever pools you like using `phpfpm::pool`.  This
type takes a bunch of parameters describing things like whether to chroot,
how to control the spawning of workers, and so on.

See the documentation for each type for all the gory details on what each
type can do, and how to make it do it.
