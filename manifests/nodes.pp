Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

node basenode {
  include "apt"
  include "backports"
  include "debian-pre"
  include "common"
  include "rvm"
  include "augeas"
  rvm_system_ruby {
   'ree-1.8.7-2012.02': 
     ensure => 'present',
     default_use => false;
  }
}

node 'blog-puppet.local' inherits basenode {
  rvm_system_ruby {
   '1.9.3-p125': 
     ensure => 'present',
     default_use => true;
  }
  include 'postgresql::v9-1'
  include 'nginx'
  iptables::role { "web-server": }
}