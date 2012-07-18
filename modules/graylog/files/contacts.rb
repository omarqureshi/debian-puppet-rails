require 'json'

# Email Notifications
God::Contacts::Email.defaults do |d|
  d.from_email = 'god@god.com'
  d.from_name = 'God'
  d.delivery_method = :sendmail
end

God.contact(:email) do |c|
  c.name = 'root'
  c.group = 'en_team'
  c.to_email = 'chris.root@edisonnation.com'
end

God.contact(:email) do |c|
  c.name = 'kirk'
  c.group = 'en_team'
  c.to_email = 'kirk.richey@edisonnation.com'
end

God.contact(:email) do |c|
  c.name = 'omar'
  c.group = 'en_team'
  c.to_email = 'omar.qureshi@edisonnation.com'
end

# Campfire Notifications
God::Contacts::Campfire.defaults do |d|
  d.subdomain = 'edisonnation'
  d.token = '90dc4b73a6d0c77fe897673718c09b3655d18407'
  d.room = 'Notifications'
  d.ssl = true
end

God.contact(:campfire) do |c|
  c.name = 'campfire_room'
end
