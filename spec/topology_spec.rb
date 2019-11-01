require 'redis'
require 'awesome_print'
require 'redbus'

RSpec.describe RedisBus do

  DEBUG_ON = true

  before :each do
    setup_test_bus
    @yaml_data = YAML.load( File.read( File.expand_path("../#{@yaml_file}", __FILE__) ) )
  end

  context "topology loader functions" do

    it "can load the yaml topology" do
      expect( @current_redbus.topology[@endpoint]['interests'].length ).to eq(2)
      expect( @current_redbus.topology['test2']['interests'].length ).to eq(2)
      expect( @current_redbus.topology['test3']['interests'] ).to be nil
    end

    it "can interrogate the topology" do
      # Get endpoints
      expect( @current_redbus.registered_endpoints.length ).to eq(@yaml_data.keys.length)
      expect( @current_redbus.registered_endpoints ).to eq(@yaml_data.keys)
      @yaml_data.keys.each do |k|
        expect( @current_redbus.registered_interests(k) ).to eq(@yaml_data[k]['interests'] || [])
      end
    end


    it "can generate subscribe_list from topology" do
      ap @current_redbus.subscribe_list if DEBUG_ON
      @yaml_data.keys.each do |k|
        ap @current_redbus.subscribe_list(k) if DEBUG_ON
        tlist = [ "@#{k}"] + (@yaml_data[k]['interests'] || []).map { |kk| "##{kk}_#{k}" }
        expect( @current_redbus.subscribe_list(k) ).to eq(tlist)
      end
    end

    it "can generate fanout_list from topology" do
      ap @current_redbus.fanout_list('interest1') if DEBUG_ON
      ap @current_redbus.fanout_list('interest2') if DEBUG_ON
      ap @current_redbus.fanout_list('interest3') if DEBUG_ON
      expect( @current_redbus.fanout_list('interest1') ).to eq(["#interest1_test1"])
      expect( @current_redbus.fanout_list('interest2') ).to eq(["#interest2_test1","#interest2_test2"])
      expect( @current_redbus.fanout_list('interest3') ).to eq(["#interest3_test2"])
    end

  end # topology loader functions

#    it "can register endpoints" do
#      Redbus::Registration.clear_registrations
#      registrations = Redbus::Registration.endpoint_registrations
#      expect(registrations.length).to eq(0)
#
#      Redbus::Registration.register_endpoint('@webhook')
#      Redbus::Registration.register_endpoint('@email')
#      Redbus::Registration.register_endpoint('@sms')
#
#      endpoints = Redbus::Registration.registered_endpoints
#      # ap endpoints
#      expect(endpoints.length).to eq(3)
#
#      registrations = Redbus::Registration.endpoint_registrations
#      # ap registrations
#      expect(registrations.length).to eq(3)
#    end
#
#    it "can register the current endpoint" do
#      Redbus::Registration.clear_registrations
#      Redbus::Registration.register_endpoint
#      endpoints = Redbus::Registration.registered_endpoints
#
#      expect(endpoints.length).to eq(1)
#      expect(endpoints[0]).to eq("@#{Redbus.endpoint}")
#    end
#
#    it "can register interests" do
#      Redbus::Registration.clear_registrations
#      registrations = Redbus::Registration.endpoint_registrations
#      expect(registrations.length).to eq(0)
#
#      Redbus::Registration.register_interest('#webhook')
#      Redbus::Registration.register_interest('#email')
#      Redbus::Registration.register_interest('#sms')
#
#      interests = Redbus::Registration.registered_interests
#      # ap interests
#      expect(interests.length).to eq(3)
#
#      registrations = Redbus::Registration.interest_registrations
#      # ap registrations
#      expect(registrations.length).to eq(3)
#    end
#
#    it "can get a subscribe list" do
#      Redbus::Registration.clear_registrations
#      registrations = Redbus::Registration.endpoint_registrations
#      expect(registrations.length).to eq(0)
#
#      Redbus::Registration.register_endpoint('@webhook')
#      Redbus::Registration.register_endpoint('@email')
#      Redbus::Registration.register_endpoint('@sms')
#
#      Redbus::Registration.register_interest('#users')
#      Redbus::Registration.register_interest('#views')
#
#      subscribe_list = Redbus::Registration.subscribe_list
#      # ap subscribe_list
#      expect(subscribe_list.length).to eq(5)
#
#    end
#
#    it "can get a fanout list" do
#      Redbus::Registration.clear_registrations
#      registrations = Redbus::Registration.endpoint_registrations
#      expect(registrations.length).to eq(0)
#
#      # Rig first endpoint
#      Redbus::Registration.register_endpoint('@users')
#      Redbus::Registration.register_interest('#users')
#      Redbus::Registration.register_interest('#views')
#
#      # Add another endpoint's worth of stuff
#      old_enpoint = Redbus.endpoint
#      Redbus.endpoint = "foobar"
#      Redbus::Registration.register_interest('#users')
#      Redbus::Registration.register_interest('#views')
#      Redbus.endpoint = old_enpoint
#
#      fanout_list = Redbus::Registration.fanout_list("#users")
#      # ap fanout_list
#      # There should be two endpoints for #users, one for each endpoint
#      expect( fanout_list.length ).to eq( 2 )
#      expect( fanout_list ).to include( "#users_foobar" )
#      expect( fanout_list ).to include( "#users_#{old_enpoint}" )
#
#    end
#
#  end # registration functions

end

