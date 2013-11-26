require 'spec_helper'

describe "phpfpm::pool" do
	let(:title) { "rspec" }

	context "no options" do
		it "bombs out" do
			expect { should contain_class("phpfpm::base") }.
			      to raise_error(Puppet::Error, /Must pass master to Phpfpm::Pool/)
		end
	end
	
	context "with just a master and user" do
		let(:params) { { :master => "rsmaster",
		                 :user   => "fred"
		             } }
		
		it "creates a config file" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_notify("Phpfpm::Master[rsmaster]")
		end
		
		it "sets the pool name" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(/^\[rspec\]$/)
		end
		
		it "sets the user" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(/^user = fred$/)
		end
		
		it "doesn't set the group" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      without_content(/^group\s*=$/)
		end
		
		it "listens to a default socket" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(%r{^listen = /etc/service/phpfpm-rsmaster/tmp/rspec.sock$})
		end

		it "sets the default strategy" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(%r{^pm = ondemand$})
		end

		it "sets the default max children" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(%r{^pm\.max_children = 10$})
		end

		it "sets the default process_idle_timeout" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(%r{^pm\.process_idle_timeout = 30s$})
		end

		it "doesn't set min_spare_servers" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      without_content(/^pm\.min_spare_servers\s*=$/)
		end
		
		it "doesn't set max_spare_servers" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      without_content(/^pm\.max_spare_servers\s*=$/)
		end
	end
	
	context "with a custom user" do
		let(:params) { { :master => "rsmaster",
		                 :user   => "bob"
		             } }
		
		it "sets the custom user" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(/^user = bob$/)
		end
	end

	context "with a custom listen spec" do
		let(:params) { { :master => "rsmaster",
		                 :user   => "fred",
		                 :listen => "127.0.0.1:9001"
		             } }
		
		it "sets the custom listen" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(/^listen = 127.0.0.1:9001$/)
		end
	end

	context "with a custom max_workers" do
		let(:params) { { :master      => "rsmaster",
		                 :user        => "fred",
		                 :max_workers => 42
		             } }
		
		it "sets the custom max_children" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(/^pm\.max_children = 42$/)
		end
	end
	
	context "with a custom idle_timeout" do
		let(:params) { { :master       => "rsmaster",
		                 :user         => "fred",
		                 :idle_timeout => "5d"
		             } }
		
		it "sets the custom process_idle_timeout" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(/^pm\.process_idle_timeout = 5d$/)
		end
	end
	
	context "with 'strategy => static'" do
		let(:params) { { :master   => "rsmaster",
		                 :user     => "fred",
		                 :strategy => "static"
		             } }
		
		it "sets the custom strategy" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(/^pm = static$/)
		end
		
		it "doesn't set process_idle_timeout" do
			expect(subject).to_not contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(/^pm\.process_idle_timeout\s*=$/)
		end

		it "doesn't set min_spare_servers" do
			expect(subject).to_not contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(/^pm\.min_spare_servers\s*=$/)
		end

		it "doesn't set max_spare_servers" do
			expect(subject).to_not contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(/^pm\.max_spare_servers\s*=$/)
		end
	end

	context "with an invalid strategy" do
		let(:params) { { :master   => "rsmaster",
		                 :user     => "fred",
		                 :strategy => "lollerskates"
		             } }
		
		it "assplodes" do
			expect { should contain_file('/error') }.
			      to raise_error(Puppet::Error, /Invalid phpfpm::pool strategy: lollerskates/)
		end
	end
	
	context "with strategy => ondemand and min_spare_workers set" do
		let(:params) { { :master            => "rsmaster",
		                 :user              => "fred",
		                 :min_spare_workers => 3
		             } }
		
		it "bombs with an informative error" do
			expect { should contain_file('/error') }.
			      to raise_error(Puppet::Error, /min_spare_workers is not valid with strategy="ondemand"/)
		end
	end
	
	context "with strategy => ondemand and max_spare_workers set" do
		let(:params) { { :master            => "rsmaster",
		                 :user              => "fred",
		                 :max_spare_workers => 3
		             } }
		
		it "bombs with an informative error" do
			expect { should contain_file('/error') }.
			      to raise_error(Puppet::Error, /max_spare_workers is not valid with strategy="ondemand"/)
		end
	end
	
	context "with strategy => dynamic" do
		let(:params) { { :master            => "rsmaster",
		                 :user              => "fred",
		                 :max_workers       => 42,
		                 :strategy          => "dynamic",
		                 :min_spare_workers => 3,
		                 :max_spare_workers => 9
		             } }

		it "sets the right strategy" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(/^pm = dynamic$/)
		end
		
		it "sets the max_children" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(/^pm\.max_children = 42$/)
		end
		
		it "sets the min_spare_servers" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(/^pm\.min_spare_servers = 3$/)
		end
		
		it "sets the max_spare_servers" do
			expect(subject).to contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(/^pm\.max_spare_servers = 9$/)
		end

		it "doesn't set process_idle_timeout" do
			expect(subject).to_not contain_file("/etc/phpfpm/rsmaster/pool.d/rspec.conf").
			      with_content(/^pm\.process_idle_timeout\s*=$/)
		end
	end
end
