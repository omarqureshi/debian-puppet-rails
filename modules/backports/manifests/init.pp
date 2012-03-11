class backports {
  apt::sources_list {"backports":
    ensure  => present,
    content => "deb http://backports.debian.org/debian-backports squeeze-backports main",
  }
}