require 'spec_helper'

describe "phpfpm::master" do
	let(:title) { "rspec" }
	# Need an OS for initscript support
	let(:facts) { { :operatingsystem => "Debian"
	            } }
	

	context "no options" do
		it "includes the base class" do
			expect(subject).to contain_class("phpfpm::base")
		end
		
		it "creates the directory" do
			expect(subject).to contain_file("/etc/phpfpm/rspec").
			      with_ensure("directory").
			      with_mode("0755")
		end
		
		it "creates the config file" do
			expect(subject).to contain_file("/etc/phpfpm/rspec/master.conf").
			      with_ensure("file").
			      with_content(%r{^include=/etc/phpfpm/rspec/pool.d/\*.conf$}).
			      with_notify("Exec[phpfpm/master/rspec:reload]")
		end
		
		it "creates .../pool.d" do
			expect(subject).to contain_file("/etc/phpfpm/rspec/pool.d").
			      with_ensure("directory").
			      with_purge(true).
			      with_recurse(true).
			      with_notify("Exec[phpfpm/master/rspec:reload]")
		end
		
		it "creates a directory for sockets" do
			expect(subject).to contain_file("/etc/service/phpfpm-rspec/tmp").
			      with_ensure("directory").
			      with_require("Daemontools::Service[phpfpm-rspec]").
			      with_mode("0710").
			      with_owner("root").
			      with_group("www-data")
		end

		it "has a daemontools service" do
			expect(subject).
			      to contain_daemontools__service("phpfpm-rspec")
		end
		
		it "has a reload exec" do
			expect(subject).
			      to contain_exec("phpfpm/master/rspec:reload").
			      with_refreshonly(true).
			      with_command("/usr/bin/svc -2 /etc/service/phpfpm-rspec")
		end

		it "runs /usr/sbin/php5-fpm" do
			expect(subject).
			      to contain_daemontools__service("phpfpm-rspec").
			      with_command("/usr/sbin/php5-fpm -y /etc/phpfpm/rspec/master.conf")
		end

		%w{RedHat CentOS}.each do |distro|
			context "on #{distro}" do
				let(:facts) { { :operatingsystem => distro
								} }
				
				it "runs /usr/sbin/php-fpm" do
					expect(subject).
							to contain_daemontools__service("phpfpm-rspec").
							with_command("/usr/sbin/php-fpm -y /etc/phpfpm/rspec/master.conf")
				end
			end
		end
		
		it "runs as root" do
			expect(subject).to contain_daemontools__service("phpfpm-rspec").
			      with_user("root").
			      with_setuid(false)
		end
	end
	
	context "with 'log_level => debug'" do
		let(:params) { { :log_level => "debug" } }
		
		it "sets log_level = debug in the config" do
			expect(subject).to contain_file("/etc/phpfpm/rspec/master.conf").
			      with_content(/^log_level = debug$/)
		end
	end
	
	context "with `max_workers => 42'" do
		let(:params) { { :max_workers => 42 } }
		
		it "sets process.max = 42 in the config" do
			expect(subject).to contain_file("/etc/phpfpm/rspec/master.conf").
			      with_content(/^process\.max = 42$/)
		end
	end

	context "with php_ini set" do
		let(:params) { { :php_ini => "/foo/bar/baz/php.ini" } }

		it "specifies php.ini in the command" do
			expect(subject).
			  to contain_daemontools__service("phpfpm-rspec").
			  with_command(%r{--php-ini /foo/bar/baz/php.ini})
		end
	end
end
