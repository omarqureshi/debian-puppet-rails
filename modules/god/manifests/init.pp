class god( $role, $ruby, $ruby_type, $gemset, $project, $rails_environment ) {
  $config_location = "GOD_CONFIG=/var/www/${project}/current/config/god/${rails_environment}/${role}-server/all.god"
  $gemset_for_rvm = "$ruby@$gemset"
  $gemset_path = "${ruby_type}-${gemset_for_rvm}"

  package { "libevent-dev": ensure => installed }

  file {"/etc/default/god":
    content => $config_location,
    owner => "root",
    group => "root",
    mode => 644,
  }

  file {"/usr/bin/god":
    owner => "root",
    group => "root",
    mode => 755,
    content => template("god/god.erb"),
  }

  rvm_gem {
    "$gemset_path/god":
      ensure => present,
      require => Rvm_gemset["$gemset_path"],
  }

  rvm_gem {
    "$gemset_path/json":
      ensure => present,
      require => Rvm_gemset["$gemset_path"],
  }

  file { "/etc/init.d/god":
    source => "puppet:///modules/god/init",
    require => [
    	        Rvm_gem["$gemset_path/god"], 
		Rvm_gem["$gemset_path/json"], 
		File["/etc/default/god"], 
		File["/usr/bin/god"], 
	 	Package["libevent-dev"]
	       ],
    owner => "root",
    group => "root",
    mode => "755",
  }

  service {"god":
    enable => true,
    ensure => running,
    require => File["/etc/init.d/god"],
  }
}