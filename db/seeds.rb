# frozen_string_literal: true

admin_email = ENV.fetch('ADMIN_EMAIL', 'admin@gmail.com')
admin_password = ENV.fetch('ADMIN_PASSWORD', 'admin@gmail.com')

User.find_or_create_by!(email: admin_email) do |user|
  user.password = admin_password
  user.password_confirmation = admin_password
  user.admin = true
end

puts "Admin user ready: #{admin_email}"

Site.find_or_create_by!(domain: 'usacars.bg') do |site|
  site.name = 'USA Cars BG'
  site.sitemap_url = 'https://usacars.bg/sitemap.xml'
  site.notes = 'Автомобілі: active / hot / resale + archive'
end

puts "Sites: #{Site.count} (#{Site.pluck(:domain).join(', ')})"
