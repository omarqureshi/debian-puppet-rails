class memcached {
  package {"memcached": ensure => installed}
  service {"memcached":
	  ensure => running,
	  require => Package["memcached"],
  }
  define server($memory="64") {
    $mem = $memory
    include memcached
    file { "/etc/memcached.conf":
             content => template("memcached/memcached.conf.erb"),
             require => Package["memcached"],
             notify => Service["memcached"],
    }
  }
}