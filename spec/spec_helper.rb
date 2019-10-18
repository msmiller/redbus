require "bundler/setup"
require "redis"
require "fakeredis"
require "redbus"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# These will be in an initializer

$redis = Redis.new # Fakeredis
$pubredis = Redis.new
$subredis = Redis.new

class Kallback

  @@chan = nil
  @@mesg = nil
  @@stash_stack = []

  DEBUG_ON = false

  def self.chan
    @@chan
  end

  def self.mesg
    @@mesg
  end

  def self.stash_stack
    @@stash_stack
  end

  def self.reset_globals
    @@chan = nil
    @@mesg = nil
    @@stash_stack = []
  end

  ####

  def self.dump(*args)
    @@chan, @@mesg = args
    x = { :channel => @@chan, :data => @@mesg }
    ap x
  end

  def self.stash(*args)
    @@chan, @@mesg = args
    puts  "stash :: #{@@chan} => #{@@mesg}" if DEBUG_ON
  end

  def self.stashstack(*args)
    @@chan, @@mesg = args
    @@stash_stack << [ @@chan, @@mesg ]
    puts  "stashstack :: #{@@chan} => #{@@mesg}" if DEBUG_ON
    ap @@stash_stack if DEBUG_ON
  end

end

class Rails

  def self.env
    "test"
  end

end
