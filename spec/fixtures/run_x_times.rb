require_relative 'fixture_helper.rb'

TheLoneDyno.exclusive(dynos: ENV.fetch("COUNT"), key_base: testing_key('run_x_times') ) do
  puts "Running locked code on: #{ Process.pid }"
end

sleep 10
