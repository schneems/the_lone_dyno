require_relative 'fixture_helper.rb'

TheLoneDyno.exclusive(key_base: testing_key('listen') ) do |signal|
  puts "Running locked code on: #{ Process.pid }"

  signal.watch(sleep: 1) do |payload|
    puts "Got signal #{payload}"
    exit(0)
  end

end


sleep 10
