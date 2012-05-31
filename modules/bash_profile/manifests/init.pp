class bash_profile {
  
  file { "/root/.profile":
    source => "puppet:///modules/bash_profile/profile",
    owner => "root",
    group => "root",
  }
  
  file { "/home/www/.profile":
    source => "puppet:///modules/bash_profile/profile",
    owner => "www",
    group => "www",
  }
  

}
