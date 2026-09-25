# frozen_string_literal: true

# Parse Sitemap seed data goes here.

admin_email = ENV.fetch('ADMIN_EMAIL', 'admin@gmail.com')
admin_password = ENV.fetch('ADMIN_PASSWORD', 'admin@gmail.com')

User.find_or_create_by!(email: admin_email) do |user|
  user.password = admin_password
  user.password_confirmation = admin_password
  user.admin = true
end

puts "Admin user ready: #{admin_email}"
