#!/usr/bin/ruby

require 'YAML'
require 'erb'
require 'pp'

fqdn = 'sample.fqdn.com' # Setting this as a stop gap before adding options

# Location of templates
template_dir = File.join(File.dirname(__FILE__), '../templates')

# Location of the console server config
con_file = File.join(File.dirname(__FILE__), '../etc/consoles', "#{fqdn}.yaml")

# Pull in the console server config
con = YAML::load_file(con_file)

# Location of users
user_dir = File.join(File.dirname(__FILE__), '../etc/users')

# Open up the user directory
dir = Dir.open(user_dir)

# Create an array to store all of the users in
users = []

# Slurp all of the users into a single array for processing by the
# template.
dir.entries.map do |user_file|
   next unless user_file =~ /\.yaml$/
   users << YAML::load_file(File.join(user_dir, user_file))
end

# Location of ports
port_dir = File.join(File.dirname(__FILE__), '../etc/ports')

# Create an array to store all of the ports in
ports = []

# Slurp all of the ports into a single array for processing by the
# template.
(1..con['num_ports']).each do |num|
   port_file = "#{con['name']}.#{num}.yaml"
   if File.exists?(File.join(port_dir, port_file))
      ports << YAML::load_file(File.join(port_dir, port_file))
   end
end

# Template parsing

# Deal with the header
header_tmpl = ERB.new(File.new(File.join(template_dir, 'header.xml.erb')).read)
puts header_tmpl.result(binding)

# Deal with the console server config
main_tmpl = ERB.new(File.new(File.join(template_dir, 'main.xml.erb')).read)
puts main_tmpl.result(binding)

# Deal with the user config
users_tmpl = ERB.new(File.new(File.join(template_dir, 'users.xml.erb')).read, 0, '>')
puts users_tmpl.result(binding)

# Port config goes here
ports_tmpl = ERB.new(File.new(File.join(template_dir, 'ports.xml.erb')).read, 0, '>')
puts ports_tmpl.result(binding)

# Deal with the footer
footer_tmpl = ERB.new(File.new(File.join(template_dir, 'footer.xml.erb')).read)
puts footer_tmpl.result(binding)
