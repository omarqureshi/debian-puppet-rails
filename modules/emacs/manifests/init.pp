class emacs {

  apt::key {"emacs":
    source => " http://emacs.naquadah.org/key.gpg"
  }

  apt::sources_list {"emacs":
    ensure  => present,
    content => "deb http://emacs.naquadah.org/ stable/",
    require => Apt::Key["emacs"]
  }

  apt::sources_list {"emacs-src":
    ensure  => present,
    content => "deb-src http://emacs.naquadah.org/ stable/",
    require => Apt::Key["emacs"]
  }

  package {"emacs-snapshot":
    ensure => installed,
    require => [Apt::Sources_list["emacs"], Apt::Sources_list["emacs-src"]]
  }

  package {"emacs-goodies-el":
    ensure => installed,
    require => Package["emacs-snapshot"],
  }
}
