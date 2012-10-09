#!/usr/bin/env ruby

require "webrick"
require "webrick/httpservlet/cgihandler"

server = WEBrick::HTTPServer.new(:Port => 8080)
cgi_script = File.expand_path("index.rb", File.dirname(__FILE__))
server.mount("/", WEBrick::HTTPServlet::CGIHandler, cgi_script)
trap(:INT) do
  server.shutdown
end
server.start
