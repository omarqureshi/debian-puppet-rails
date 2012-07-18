PID_DIR       = '/var/www/translator.edisonnation.com/shared/pids'
RAILS_ENV     = 'production'
RAILS_ROOT    = '/var/www/translator.edisonnation.com/current'
BIN_PATH      = "/usr/local/rvm/rubies/ruby-1.9.3-p194/bin/ruby"

God.log_file  = "/var/log/god.log"
God.log_level = :info


['nginx','unicorn'].each do |config|
  God.load "#{RAILS_ROOT}/config/god/configs/#{config}.god"
end

require '/var/www/translator.edisonnation.com/current/config/god/configs/contacts.rb'