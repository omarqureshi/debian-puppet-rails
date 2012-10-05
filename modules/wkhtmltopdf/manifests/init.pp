class wkhtmltopdf {

  package {"wkhtmltopdf": ensure => removed }
  file {"/usr/bin/wkhtmltopdf":
    source => "puppet:///modules/wkhtmltopdf/whkhtmltopdf",
    force => true,
    require => Package['wkhtmltopdf'],
  }
  
}
