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
     default_use => false,
  }
}

node 'ruby-193' inherits basenode {
  rvm_system_ruby {
   '1.9.3-p125': 
     ensure => 'present',
     default_use => true,
  }
  rvm_gem {
    'ruby-1.9.3-p125@global/bundler':
      ensure => latest,
      require => Rvm_system_ruby['1.9.3-p125'],
  }
}

node 'ruby-193-web' inherits 'ruby-193' {
  iptables::role { "web-server": }
}


node 'en-copycopter' inherits 'ruby-193-web' {
  include 'postgresql::v9-1'
  rvm_gemset {
    "ruby-1.9.3-p125@copycopter":
      ensure => present,
      require => Rvm_system_ruby['1.9.3-p125'],
  }
  nginx::unicorn_site { 'copycopter': }
  class { "god": 
     rails_environment => "development",
     role => "all",
     ruby => "1.9.3-p125",
     gemset => "copycopter",
     ruby_type => "ruby",
  }
}

