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

    it "can load default config" do
      expect(Redbus.timeout).to eq(5)
    end

    it "can set default config" do
      old_enpoint = Redbus.endpoint
      Redbus.endpoint = "foobar"
      expect(Redbus.endpoint).to eq("foobar")
      Redbus.endpoint = old_enpoint
      expect(Redbus.endpoint).to eq(old_enpoint)
    end

    it "can generate a rpc_token" do
      expect(Redbus::Support.rpc_token).to_not be nil
    end

  end # support functions

  context "registration functions" do

    it "can register endpoints" do
      Redbus::Registration.clear_registrations
      registrations = Redbus::Registration.endpoint_registrations
      expect(registrations.length).to eq(0)

      Redbus::Registration.register_endpoint('@webhook')
      Redbus::Registration.register_endpoint('@email')
      Redbus::Registration.register_endpoint('@sms')

      endpoints = Redbus::Registration.registered_endpoints
      # ap endpoints
      expect(endpoints.length).to eq(3)

      registrations = Redbus::Registration.endpoint_registrations
      # ap registrations
      expect(registrations.length).to eq(3)
    end

    it "can register the current endpoints" do
      Redbus::Registration.clear_registrations
      Redbus::Registration.register_endpoint
      endpoints = Redbus::Registration.registered_endpoints

      expect(endpoints.length).to eq(1)
      expect(endpoints[0]).to eq("@#{Redbus.endpoint}")
    end

    it "can register interests" do
      Redbus::Registration.clear_registrations
      registrations = Redbus::Registration.endpoint_registrations
      expect(registrations.length).to eq(0)

      Redbus::Registration.register_interest('#webhook')
      Redbus::Registration.register_interest('#email')
      Redbus::Registration.register_interest('#sms')

      interests = Redbus::Registration.registered_interests
      # ap interests
      expect(interests.length).to eq(3)

      registrations = Redbus::Registration.interest_registrations
      # ap registrations
      expect(registrations.length).to eq(3)
    end

    it "can get a subscribe list" do
      Redbus::Registration.clear_registrations
      registrations = Redbus::Registration.endpoint_registrations
      expect(registrations.length).to eq(0)

      Redbus::Registration.register_endpoint('@webhook')
      Redbus::Registration.register_endpoint('@email')
      Redbus::Registration.register_endpoint('@sms')

      Redbus::Registration.register_interest('#users')
      Redbus::Registration.register_interest('#views')

      subscribe_list = Redbus::Registration.subscribe_list
      # ap subscribe_list
      expect(subscribe_list.length).to eq(5)

    end

    it "can get a fanout list" do
      Redbus::Registration.clear_registrations
      registrations = Redbus::Registration.endpoint_registrations
      expect(registrations.length).to eq(0)

      Redbus::Registration.register_endpoint('@webhook')
      Redbus::Registration.register_endpoint('@email')
      Redbus::Registration.register_endpoint('@sms')

      Redbus::Registration.register_interest('#users')
      Redbus::Registration.register_interest('#views')

      # Add another endpoint's worth of stuff
      old_enpoint = Redbus.endpoint
      Redbus.endpoint = "foobar"
      Redbus::Registration.register_interest('#users')
      Redbus::Registration.register_interest('#views')
      Redbus.endpoint = old_enpoint

      fanout_list = Redbus::Registration.fanout_list("#users")
      # ap fanout_list
      expect(fanout_list.length).to eq(2)

    end

  end # registration functions

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

####    it "can handle subscribe timeout" do
####      ap Kallback.chan
####      ap Kallback.mesg
####      #Redbus::Lpubsub.publish( "@test", { "foo" => "bar" } )
####      expect($pubredis.llen("@test")).to eq(0)
####      ap Redbus::Lpubsub.subscribe_once( "@test", "Kallback::stash" )
####      ap Kallback.chan
####      ap Kallback.mesg
####      # Redbus::Lpubsub.subscribe_once( "@test", "Kallback::dump" )
####    end

  end # lpubsub

end

