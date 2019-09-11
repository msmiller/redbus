require 'redis'
require 'redis-objects'
require 'awesome_print'

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
  end
end

# k = Kallback.new
# k.send :hello, "gentle", "readers"   #=> "Hello gentle readers"

RSpec.describe Redbus do

  before :each do
    Kallback.reset_globals
    Redbus::Lpubsub.clear_channel("@test")
  end

  context "support functions" do

    it "has a version number" do
      expect(Redbus::VERSION).not_to be nil
    end

    it "can generate a rpc_token" do
      expect(Redbus::Support.rpc_token).to_not be nil
    end

    it "can register endpoints" do
      Redbus::Support.register_endpoint('webhook')
      Redbus::Support.register_endpoint('email')
      Redbus::Support.register_endpoint('sms')
      endpoints = Redbus::Support.registered_endpoints
      expect(endpoints.length).to eq(3)
      # ap endpoints
      registrations = Redbus::Support.endpoint_registrations
      expect(registrations.length).to eq(3)
      # ap registrations
    end

  end # support functions

  context "lpubsub" do

    it "can publish to a channel" do
      expect($pubredis.llen("@test")).to eq(0)
      Redbus::Lpubsub.publish( "@test", { "foo" => "bar" } )
      expect($pubredis.llen("@test")).to eq(1)
    end

    it "can publish to a channel-list" do
      expect($pubredis.llen("@test1")).to eq(0)
      expect($pubredis.llen("@test2")).to eq(0)
      Redbus::Lpubsub.publish( "@test1,@test2", { "foo" => "bar" } )
      Redbus::Lpubsub.publish( "@test1,@test2", { "ack" => "oop" } )
      Redbus::Lpubsub.publish( "@test", { "foo" => "bar" } )
      expect($pubredis.llen("@test1")).to eq(2)
      expect($pubredis.llen("@test2")).to eq(2)
    end

    it "can subscribe_once" do
      #ap Kallback.chan
      #ap Kallback.mesg
      Redbus::Lpubsub.publish( "@test", { "foo" => "bar" } )
      Redbus::Lpubsub.subscribe_once( "@test", "Kallback::stash" )
      #ap Kallback.chan
      #ap Kallback.mesg
      # Redbus::Lpubsub.subscribe_once( "@test", "Kallback::dump" )
    end

    it "can handle subscribe timeout" do
      ap Kallback.chan
      ap Kallback.mesg
      #Redbus::Lpubsub.publish( "@test", { "foo" => "bar" } )
      expect($pubredis.llen("@test")).to eq(0)
      ap Redbus::Lpubsub.subscribe_once( "@test", "Kallback::stash" )
      ap Kallback.chan
      ap Kallback.mesg
      # Redbus::Lpubsub.subscribe_once( "@test", "Kallback::dump" )
    end

  end # lpubsub

end

