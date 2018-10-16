require "pry"
require "json"
require "doc_integrity_check"
require "socket"
require "curb"
require "sinatra"
load "index_server.rb"

# Set docmanager url
ENV["DOCMANAGER_URL"] = "http://localhost:3000" if ENV["DOCMANAGER_URL"] == nil

run IndexServer
