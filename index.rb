#!/usr/bin/ruby
require 'drb/drb'

DRb.start_service('druby://localhost:0')
wikir = DRbObject.new_with_uri('druby://localhost:50830')
wikir.start(ENV.to_hash, $stdin, $stdout)
