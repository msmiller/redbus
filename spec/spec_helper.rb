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
$pubredis = $redis
$subredis = $redis

class Kallback

  @@chan = nil
  @@mesg = nil

  def self.chan
    @@chan
  end

  def self.mesg
    @@mesg
  end

  def self.reset_globals
    @@chan = nil
    @@mesg = nil
  end

  ####

  def self.dump(*args)
    x = { :channel => args[0], :data => args[1] }
    ap x
  end

  def self.stash(*args)
    @@chan = args[0]
    @@mesg = args[1]
    ap "#{@@chan} => #{@@mesg}"
  end
end
