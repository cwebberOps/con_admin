#!/usr/bin/ruby

require 'rubygems'
require 'optparse'
require 'net/ssh'

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

# Read in the public key that will be used to get into the console servers
pubkey_file = File.join(File.dirname(__FILE__), '../etc/ssh_keys/id_rsa.pub')
begin
   pubkey = File.read(pubkey_file)
rescue
   puts "Error: Please ensure the public key exists at #{pubkey_file}"
end

# ssh to the cosole server and put the key in place.
Net::SSH.start(fqdn,'root') do |ssh|
   ssh.exec!("echo \"#{pubkey}\" > .ssh/authorized_keys")
   # TODO: Pull down the config and generate the appropriate yaml
end

