#!/usr/bin/ruby

require 'YAML'
require 'erb'
require 'pp'
require 'optparse'
require 'rubygems'
require 'net/ssh'
require 'net/scp'

options = {}
optparse = OptionParser.new do |opts|
   opts.banner = "Usage: #{File.basename(__FILE__)} [options]"

   opts.on("-h",
      "--help",
      "Display this screen"
   ) do
      puts opts
      exit
   end

   options[:noop] = false
   opts.on("-n",
      "--noop",
      "Don't make any changes, just output the resultant config."
   ) do |noop|
      options[:noop] = noop
   end

   opts.on("-s",
      "--server FQDN",
      "FQDN of console server to be configured"
   ) do |fqdn|
      options[:server] = fqdn
   end

end

begin
   optparse.parse!
   mandatory = [:server]
   missing = mandatory.select{ |param| options[param].nil? }
   unless missing.empty?
      puts "Missing options: #{missing.join(', ')}"
      puts optparse
      exit 1
   end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
   puts $!.to_s
   puts optparse
   exit 1
end

fqdn = options[:server] # Setting this as a stop gap before adding options

# Location of templates
template_dir = File.join(File.dirname(__FILE__), '../templates')

# Location of the console server config
con_file = File.join(File.dirname(__FILE__), '../etc/consoles', "#{fqdn}.yaml")

# Pull in the console server config
begin
   con = YAML::load_file(con_file)
rescue
   puts "Error: #{con_file} could not be read or does not exist"
   exit 1
end

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
config_content = ''

# Deal with the header
header_tmpl = ERB.new(File.new(File.join(template_dir, 'header.xml.erb')).read)
config_content << header_tmpl.result(binding)

# Deal with the console server config
main_tmpl = ERB.new(File.new(File.join(template_dir, 'main.xml.erb')).read)
config_content << main_tmpl.result(binding)

# Deal with the user config
users_tmpl = ERB.new(File.new(File.join(template_dir, 'users.xml.erb')).read, 0, '>')
config_content << users_tmpl.result(binding)

# Port config goes here
ports_tmpl = ERB.new(File.new(File.join(template_dir, 'ports.xml.erb')).read, 0, '>')
config_content << ports_tmpl.result(binding)

# Deal with the footer
footer_tmpl = ERB.new(File.new(File.join(template_dir, 'footer.xml.erb')).read)
config_content << footer_tmpl.result(binding)

unless options[:noop]

   var_dir = File.join(File.dirname(__FILE__), '../var')

   unless File.exists?(var_dir)
      if File.writeable?(File.join(File.dirname(__FILE__), '..'))
         Dir.mkdir(var_dir)
      else
         puts "Error: Unable to create #{var_dir}"
         exit 1
      end
   end

   if File.directory?(var_dir) && File.writable?(var_dir)
      host_dir = File.join(var_dir, fqdn)
      unless File.directory?(host_dir)
         if File.exists?(host_dir)
            puts "Error: #{host_dir} is a file and not a direcory"
            exit 1
         else
            Dir.mkdir(host_dir)
         end
      end
      
      File.open(File.join(host_dir, 'config.xml.new'), 'w') do |file|
         file.puts config_content
      end
      
   end

   # TODO: Write out the new config.xml for the console server
   # TODO: Ensure that the console server can be connected to without a password
   # TODO: Copy down the current config and store it
   # TODO: Copy up the new config file
   # TODO: Run the config parser

else
   puts config_content
end
