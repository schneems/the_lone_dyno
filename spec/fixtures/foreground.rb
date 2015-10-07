require_relative 'fixture_helper.rb'

TheLoneDyno.exclusive(background: false, key_base: testing_key('foreground') ) do
  puts "foreground 1"
end

TheLoneDyno.exclusive(background: false, key_base: testing_key('foreground') ) do
  puts "foreground 2"
end
