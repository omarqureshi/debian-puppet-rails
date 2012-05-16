class memcached($memory="64") {
  $mem = $memory
  package {"memcached": ensure => installed}
  service {"memcached":
	  ensure => running,
	  require => Package["memcached"],
  }

  file { "/etc/memcached.conf":
             content => template("memcached/memcached.conf.erb"),
             require => Package["memcached"],
             notify => Service["memcached"],
  }
}