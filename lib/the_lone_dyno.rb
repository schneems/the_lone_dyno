require "the_lone_dyno/version"
require "hey_you"

module TheLoneDyno
  DEFAULT_KEY = "the_lone_dyno_hi_ho_silver"
  DEFAULT_PROCESS_TYPE = "web"

  # Use to ensure only `dynos` count of dynos are exclusively running
  # the given block
  def self.exclusive(dynos: 1, process_type: DEFAULT_PROCESS_TYPE, background: true, sleep: 60, ttl: 0.1, connection: ::HeyYou::DEFAULT_CONNECTION_CONNECTOR.call, key_base: DEFAULT_KEY, **args, &block)
    dynos = dyno_names(dynos, process_type)

    return unless dynos.include?(ENV['DYNO'])

    watcher = ListenWatch.new(ENV['DYNO'] + key_base, connection)

    if background
      Thread.new do
        forever_block = Proc.new { |*a| block.call(*a); while true do; sleep 180 ; end; }
        forever_block.call(watcher)
      end
    else
      block.call(watcher)
    end
  end

  def self.dyno_names(dynos, process_type)
    1.upto(dynos.to_i).map { |i| "#{process_type}.#{i}" }
  end

  # Use to send a custom signal to any exclusive running dynos
  def self.signal(payload = "", dynos: 1, process_type: DEFAULT_PROCESS_TYPE, key_base: DEFAULT_KEY, connection: ::HeyYou::DEFAULT_CONNECTION_CONNECTOR.call, **args, &block)
    dynos = dyno_names(dynos, process_type)

    dynos.each do |dyno|
      HeyYou.new(channel: (dyno + key_base).gsub(".".freeze, "_".freeze), connection: connection).notify(payload)
    end
  end

  # Used for running a block when a pg NOTIFY is sent
  class ListenWatch
    def initialize(key, raw_connection)
      @key = key.gsub(".".freeze, "_".freeze)
      @raw_connection = raw_connection
    end

    def watch(sleep: 60, ttl: 0.01, &block)
      HeyYou.new(sleep: sleep, ttl: ttl, channel: @key, connection: @raw_connection).listen(&block)
    end
  end
end
