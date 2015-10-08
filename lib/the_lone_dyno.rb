require "the_lone_dyno/version"
require "pg_lock"

module TheLoneDyno
  DEFAULT_KEY = "the_lone_dyno_hi_ho_silver"

  # Use to ensure only `dynos` count of dynos are exclusively running
  # the given block
  def self.exclusive(background: true, dynos: 1, key_base: DEFAULT_KEY, connection: ::PgLock::DEFAULT_CONNECTION_CONNECTOR.call, &block)
    if background
      Thread.new do
        forever_block = Proc.new { |*args| block.call(*args); while true do; sleep 180 ; end; }
        Lock.new(key_base, dynos).lock(connection, &forever_block)
      end
    else
      Lock.new(key_base, dynos).lock(connection, &block)
    end
  end

  # Use to send a custom signal to any exclusive running dynos
  def self.signal(payload = "", dynos: 1, key_base: DEFAULT_KEY, connection: ::PgLock::DEFAULT_CONNECTION_CONNECTOR.call, &block)
    Lock.new(key_base, dynos).keys.each do |key|
      message = "NOTIFY #{key}, '#{payload}'"
      puts message
      connection.exec(message)
    end
  end

  # Used for running a block when a pg NOTIFY is sent
  class ListenWatch
    def initialize(key, raw_connection)
      @key = key
      @raw_connection = raw_connection
    end

    def watch(sleep: 60, ttl: 0.01, &block)
      @raw_connection.exec "LISTEN #{@key}"

      @thread = Thread.new do
        while true do
          sleep sleep

          @raw_connection.wait_for_notify(ttl) do |channel, pid, payload|
            block.call(payload)
          end
        end
      end
    end
  end

  # Used for generating lock and listen keys. Isolates
  # advisory locking behavior.
  class Lock
    def initialize(key_base, dynos, &block)
      @key_base = key_base.to_s
      @dynos    = Integer(dynos)
      @block    = block
    end

    def keys
      @dynos.times.map {|i| "#{@key_base}_#{i}" }
    end

    def lock(connection, &block)
      keys.each do |key|
        PgLock.new(name: key, ttl: false, connection: connection).lock do
          block.call(ListenWatch.new(key, connection))
        end
      end
    end
  end
end
