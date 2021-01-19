require 'redis'
require 'awesome_print'

RSpec.describe RedBus do

  before :each do
    # In this case we don't want to clear the bus in between ever time
    @yaml_file = 'redbus_topology.yml'
    @endpoint = 'test1'
    @current_redbus = RedBus.new(@endpoint, @yaml_file)
    @current_redbus.gather_stats = true
  end

  context "stats" do

    it "can bump a count" do
      @current_redbus.busredis.flushall
      @current_redbus.busredis.flushdb
      x = @current_redbus.bump( "@test1", "published" )
      y = @current_redbus.bump( "@test1", "processed" )
      y = @current_redbus.bump( "@test1", "processed" )
      z = @current_redbus.bump( "@test1", "failed" )
      z = @current_redbus.bump( "@test1", "failed" )
      z = @current_redbus.bump( "@test1", "failed" )
      expect(x).to eq(1)
      expect(y).to eq(2)
      expect(z).to eq(3)
    end

    it "can clear channel stats (Use data left from prior test)" do
      count_keys = @current_redbus.busredis.keys( "stats:*" )
      expect(count_keys.length).to eq(3)
      # Clear data left from prior test
      @current_redbus.clear( "@test1" )
      count_keys = @current_redbus.busredis.keys( "stats:*" )
      expect(count_keys.length).to eq(0)
    end

    it "can gather stats" do
      load_some_data
      yr = Date.today.year
      mo = Date.today.month
      counts = @current_redbus.counts_for( "@test1" )
      expect(counts.length).to eq(3)
      expect(counts["published"][yr][mo]).to eq(1)
      expect(counts["processed"][yr][mo]).to eq(2)
      expect(counts["failed"][yr][mo]).to eq(3)
    end

  end # stats

  def load_some_data
    @current_redbus.bump( "@test1", "published" )
    @current_redbus.bump( "@test1", "processed" )
    @current_redbus.bump( "@test1", "processed" )
    @current_redbus.bump( "@test1", "failed" )
    @current_redbus.bump( "@test1", "failed" )
    @current_redbus.bump( "@test1", "failed" )
  end

end

