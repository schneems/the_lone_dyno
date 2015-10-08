require 'active_record'
require 'the_lone_dyno'

STDOUT.sync = true

begin
  ActiveRecord::Base.establish_connection(
    adapter:  'postgresql',
    database: 'the_lone_dyno_test'
  )
  ActiveRecord::Base.connection.raw_connection.exec("select 1")
rescue ActiveRecord::NoDatabaseError => e
  msg = "\nCreate a database to continue `$ createdb pg_lock_test` \n" + e.message
  raise e, msg
end

def testing_key(base = nil)
  [base, ENV["TRAVIS_BUILD_ID"] , ENV["TRAVIS_JOB_ID"] ].compact.join("_")
end
