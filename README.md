![The Lone Dyno logo](https://www.dropbox.com/s/m7v8yndgcgt8sf3/Screenshot%202015-10-08%2014.42.32.png?dl=1)

# TheLoneDyno

Isolate code to only run on a certain number of Heroku dynos. Using and Postgres [advisory locks](http://www.postgresql.org/docs/9.1/static/explicit-locking.html). You can later trigger events using Postgres listen/notify.

## Why?

Why would you want to run code on only one dyno? Maybe you want to add some performance monitoring code to a critical path in production, you don't want to slow down all your dynos, so you can retain throughput by isolating to only run on one dyno. Maybe you want to test out a refactoring or change, instead of rolling it out to all of your service, you could run it on a select number. Whatever the reason, if you want to run some code on only a few dynos, this is the gem for you!

Why is this needed? All Heroku dynos operate independently of one another. Once one is running you can't change it. You can `$ heroku run bash` but this gives you a new dyno that doesn't receieve any web traffic. If you want to run code on only a certain number of dynos it's been difficult to do so until now.

> Be warned, only changing behavior on 1 dyno in your app, could cause difficult to reproduce problems. "I'm getting an error but only once fore every 20 requests". Using this library is an advanced technique and should be implemented with care. Make sure to tell the rest of your team what you're doing, and remove the code from your codebase as soon as you're done.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'the_lone_dyno'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install the_lone_dyno

## Usage

In an initializer like `config/initializers/the_lone_dyno.rb` configure your code:

```ruby
TheLoneDyno.exclusive do
  while true do
    # Code that only runs in 1 dyno in the background
    puts "bump-ba-da-bump-ba-da-bump"
    sleep 1
  end
end

puts "Does not block future code execution"
```

This code will only run on one dyno. By default code passed into the block will run in the background and the lock will be held for as long as your process is alive. For example if we run the above code we should get:

```
Does not block future code execution
bump-ba-da-bump-ba-da-bump
bump-ba-da-bump-ba-da-bump
bump-ba-da-bump-ba-da-bump
bump-ba-da-bump-ba-da-bump
bump-ba-da-bump-ba-da-bump
# ...
```

So your app will continue to load and run as usual.

Note: The Lone Dyno restricts code at the process/machine level. While it will prevent this code from being executed on multiple machines it is not restricted from running multiple times in the same process. If you are calling this code in multiple threads it will execute in every thread. If that's not what you want, you'll need to add your own mutex.

## Triggering Events

Sometimes you'll need to interact with your Lone Dyno externally. You can trigger events with listen/notify.

```ruby
TheLoneDyno.exclusive do |signal|
  # Code you only want to run on 1 dyno

  signal.watch do |payload|
    puts "I only get called when I receive the signal: #{payload}"
  end
end
```

The code you are running inside of the `watch` block will run in a background thread waiting for a notification. How do you send a signal? You can do so with `$ heroku run bash`

```
$ heroku run bash
$ rails console
>
> TheLoneDyno.signal("hi ho silver!")
```

When you do this 1 and only one dyno will emit

```
"I only get called when I receive the signal: hi ho silver"
```

Whatever configuration you pass into `TheLoneDyno#exclusive` need to be passed into `TheLoneDyno#signal` such as `key_base` and `dynos`. See configuration options below. This is needed since each dyno maintains a unique lock, we re-use the same name to signal the same dyno using postgres' [Listen/Notify](http://www.postgresql.org/docs/9.1/static/sql-notify.html).

 By default the background thread wakes up every 60 seconds and waits 0.1 seconds to see if there is a message. You can customize this behavior using `sleep` and `ttl`. So to have it check every 10 seconds, and not wait at all you could run

```ruby
TheLoneDyno.exclusive do |signal|
  # Code you only want to run on 1 dyno

  signal.watch(sleep: 10, ttl: 0) do |payload|
    puts "I only get called when I receive the signal: #{payload}"
  end
end
```

## Config

You can control the number of dynos you run code on by passing in an integer:

```ruby
TheLoneDyno.exclusive(dynos: 5) do
  # Code you only want to run on 5 dyno
end
```

Under the hood this uses PG advisory locks. If you need to customize the default advisory key, for instance if you want to have multiple processes you want to isolate to a set of dynos you can use the `key_base:` key, for example:

```ruby
TheLoneDyno.exclusive(key_base: "reticulate splines") do
  # Code for reticulating splines
end

TheLoneDyno.exclusive(dynos: 42, key_base: "extrapolate conclusions") do
  # Code for extrapolating conclusions
end
```

## Run Syncronously in the Foreground

If you don't want to run your exclusive process in the background you can force it to run syncronously using `background: false`. For example:


```ruby
TheLoneDyno.exclusive(background: false) do |signal|
  while true do
    puts "bump-ba-da-bump-ba-da-bump"
    sleep 1
  end
end

puts "Does block execution"
```

produces

```
bump-ba-da-bump-ba-da-bump
bump-ba-da-bump-ba-da-bump
bump-ba-da-bump-ba-da-bump
bump-ba-da-bump-ba-da-bump
bump-ba-da-bump-ba-da-bump
# ...
```

Notice the `puts "Does block execution"` never gets called because our Lone Dyno block never exits.

Keep in mind that your lock is only held for the duration of your block, so if the code in your block exits, another machine may be able to pick up the lock. For this reason it is recommended to not run short tasks syncronously in the foreground.


## Connection

By default The Lone Dyno assumes you're using Active Record and already have a connection configured. If you want to use a different ORM, you'll need to provide TheLoneDyno with an object that responds to `exec` that executes arbitrary SQL. Under the hood this library uses [pg_lock](https://github.com/heroku/pg_lock#database-connection). So that's how you can configure the connection

```
connection = Module do
  def self.exec(sql, bind)
    DB.fetch(sql, bind)
  end
end

TheLoneDyno.exclusive(connection: connection)  do

end
```

You can alternatively set the `DEFAULT_CONNECTION`

```
Pg::Lock = Module do
  def self.exec(sql, bind)
    DB.fetch(sql, bind)
  end
end

TheLoneDyno.exclusive  do

end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/the_lone_dyno. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

