class jenkins {
  apt::key {"jenkins":
    source => "http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key",
  }
  
  apt::sources_list {"jenkins":
    ensure => present,
    content => "deb http://pkg.jenkins-ci.org/debian binary/",
    require => Apt::Key["jenkins"]
  }

  package {"jenkins": ensure => installed }

}