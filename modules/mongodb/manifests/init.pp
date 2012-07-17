class mongodb($auth=false) {

  $_auth = $auth
  
  package {"mongodb": ensure => installed }
  
  file {"/etc/mongodb.conf":
    content => template("mongodb/mongodb.conf.erb"),
    require => Package["mongodb"],
    notify  => Service["mongodb"],
  }

  service { "mongodb":
    enable => true,
    ensure => running,
    require => Package["mongodb"],
  }

}
