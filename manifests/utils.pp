define append_if_no_such_line($file, $line) {
  exec { "/bin/echo '$line' >> '$file'":
    unless => "/bin/grep -Fx '$line' '$file'",
  }
}