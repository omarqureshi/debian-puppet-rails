class dnsmasq($hosts=[]) {
  $hostnames = $hosts
  
  package { "dnsmasq": ensure => installed }
  service { "dnsmasq": 
    enable => true,
    ensure => running,
    require => Package["dnsmasq"],
    subscribe => File["/etc/dnsmasq.conf"],
  }

  file {"/etc/dnsmasq.conf":
    content => template("dnsmasq/dnsmasq.conf.erb"),
    require => Package["dnsmasq"],
  }

}