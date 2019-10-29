require 'redis'
require 'awesome_print'

class Frodus
  def id
    5678
  end

  def to_json
    { id: 5678, ack: 'oop', foo: 'bar' }.to_json
  end
end


RSpec.describe Redbus::Cachethru do

  before :each do
  end

  context "key generation" do

    it "can generate key from hash" do
      k = Redbus::Cachethru._redis_key( {class: 'Foo', id: 1234} )
      expect(k).to eq( "#{Redbus::CACHETHRU_KEY_ROOT}.Foo.1234" )
    end

    it "can generate key from model" do
      f = Frodus.new
      k = Redbus::Cachethru._redis_key( f )
      expect(k).to eq( "#{Redbus::CACHETHRU_KEY_ROOT}.Frodus.5678" )
    end

  end # key generation

  context "cached objects" do

    it "can get an object across an rpc request" do

      # set up
      $redis.flushall
      $redis.flushdb
      Kallback.reset_globals
      Redbus::Registration.register_endpoint("@test")
      Redbus::Lpubsub.clear_channel("@test")

      # Arm the cachethru send
      cachethru_result = nil
      Thread.new do
        # Wait 1/10th of a second so the responder can spin up
        sleep(0.1)
        cachethru_result = Redbus::Cachethru.retrieve( 'Frodus', 5678, "@test" )
      end

      # This will handle the rpc request and send back data
      chan, mesg = $subredis.blpop("@test") #, :timeout => Redbus.timeout)
      if mesg
        data = JSON.parse(mesg)
        sub_result = data
        f = Frodus.new
        Redbus::Cachethru.deposit(f, data['rpc_token'])
      end

      # Wait a beat to let the threads unwind. This won't be needed in the wild, but since
      # we're running tests locally it's so blazingly fast it creates race condition
      sleep(0.25)

      # p "RESULT: "
      # ap cachethru_result
      expect( cachethru_result.id ).to eq( 5678 )
      expect( cachethru_result.ack ).to eq( "oop" )
      expect( cachethru_result.foo ).to eq( "bar" )
    end

    it "can get remove a cached object" do
      # set up
      $redis.flushall
      $redis.flushdb
      Kallback.reset_globals
      Redbus::Registration.register_endpoint("@test")
      Redbus::Lpubsub.clear_channel("@test")

      f = Frodus.new
      Redbus::Cachethru.deposit(f)
      Redbus.cremove( 'Frodus', 5678 )
    end

  end # cached objects



end

