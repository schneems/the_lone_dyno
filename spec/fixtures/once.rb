require_relative 'fixture_helper.rb'

TheLoneDyno.exclusive(key_base: testing_key('once') ) do
  puts "Running locked code on: #{ Process.pid }"
end

sleep 5
