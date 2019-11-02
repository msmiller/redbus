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


RSpec.describe RedisBus do

  before :each do
  end

  context "key generation" do

    it "can generate key from hash" do
      k = RedisBus::_redis_key( {class: 'Foo', id: 1234} )
      expect(k).to eq( "#{Redbus::CACHETHRU_KEY_ROOT}.Foo.1234" )
    end

    it "can generate key from model" do
      f = Frodus.new
      k = RedisBus::_redis_key( f )
      expect(k).to eq( "#{Redbus::CACHETHRU_KEY_ROOT}.Frodus.5678" )
    end

  end # key generation

  context "cached objects" do

    it "can get an object across an rpc request" do

      Kallback.reset_globals
      setup_test_bus
      @current_redbus.busredis.flushall
      @current_redbus.busredis.flushdb
      @current_redbus.clear_channel("@test1")

      # Arm the cachethru send
      cachethru_result = nil
      Thread.new do
        # Wait 1/10th of a second so the responder can spin up
        sleep(0.1)
        cachethru_result = @current_redbus.retrieve( 'Frodus', 5678, "@test1" )
      end

      # This will handle the rpc request and send back data
      chan, mesg = @current_redbus.subredis.blpop("@test1") #, :timeout => Redbus.timeout)
      if mesg
        data = JSON.parse(mesg)
        sub_result = data
        f = Frodus.new
        @current_redbus.deposit(f, data['rpc_token'])
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

    it "can get a json hashed object across an rpc request" do

      # set up
      Kallback.reset_globals
      setup_test_bus
      @current_redbus.busredis.flushall
      @current_redbus.busredis.flushdb
      @current_redbus.clear_channel("@test1")

      # Arm the cachethru send
      cachethru_result = nil
      Thread.new do
        # Wait 1/10th of a second so the responder can spin up
        sleep(0.1)
        cachethru_result = @current_redbus.retrieve( 'Frodus', 5678, "@test1" )
      end

      # This will handle the rpc request and send back data
      chan, mesg = @current_redbus.subredis.blpop("@test1") #, :timeout => Redbus.timeout)
      if mesg
        data = JSON.parse(mesg)
        sub_result = data
        f = Frodus.new
        s = { 'id' => 2468, 'hashone' => 1, 'hashtwo' => 2 }.to_json
        @current_redbus.deposit(f, data['rpc_token'], nil, s)
      end

      # Wait a beat to let the threads unwind. This won't be needed in the wild, but since
      # we're running tests locally it's so blazingly fast it creates race condition
      sleep(0.25)

      # p "RESULT: "
      # ap cachethru_result
      expect( cachethru_result.id ).to eq( 2468 )
      expect( cachethru_result.hashone ).to eq( 1 )
      expect( cachethru_result.hashtwo ).to eq( 2 )
    end
    
    it "can get remove a cached object" do
      # set up
      Kallback.reset_globals
      setup_test_bus
      @current_redbus.busredis.flushall
      @current_redbus.busredis.flushdb
      @current_redbus.clear_channel("@test1")

      f = Frodus.new
      @current_redbus.deposit(f)
      @current_redbus.cremove( 'Frodus', 5678 )
    end

  end # cached objects



end

