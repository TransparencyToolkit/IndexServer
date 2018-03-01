require "pry"
require "json"
require "doc_integrity_check"
require "socket"
require "curb"
load "udp_server.rb"

# Load all files
#Dir.glob('*.rb').each { |file| require file }

run UdpServer
