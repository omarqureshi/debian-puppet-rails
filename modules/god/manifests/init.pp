class god( $rails_environment, $role, $ruby, $ruby_type, $gemset ) {
  $config_location = "GOD_CONFIG=/var/www/$gemset/current/config/god/$rails_environment/$role/all.god"
  $gemset_for_rvm = "$ruby@$gemset"
  $gemset_path = "${ruby_type}-${gemset_for_rvm}"

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

  file { "/etc/init.d/god":
    source => "puppet:///modules/god/init",
    require => [Rvm_gem["$gemset_path/god"], File["/etc/default/god"], File["/usr/bin/god"]],
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