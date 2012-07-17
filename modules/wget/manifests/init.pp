class wget {
  package { "wget": ensure => latest }
}

define wget::fetch($source,$destination) {
  exec { "wget-$name":
    command => "/usr/bin/wget --output-document=$destination $source",
    creates => "$destination",
  }
}
