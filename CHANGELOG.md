# A Log of Changes!

## [1.0.0] - 2015-11-06

- Exclusivity is no longer provided by advisory locks instead uses a naming convention
  provided by ENV['DYNO']. Prior implementation had the problem that on Puma or unicorn
  the lock would be aquired by the master process but not the puma workers . Most likely we want
  the workers to be doing tasks.

## [0.1.1] - 2015-10-12

- Restrict locking behavior by process type. Default is "web".

## [0.1.0]

- First version.
