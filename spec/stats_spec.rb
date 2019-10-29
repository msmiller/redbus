require 'redis'
require 'awesome_print'

RSpec.describe Redbus::Stats do

  before :each do
  end

  context "stats" do

    it "can bump a count" do
      x = Redbus::Stats.bump( "@test1", "published" )
      y = Redbus::Stats.bump( "@test1", "processed" )
      y = Redbus::Stats.bump( "@test1", "processed" )
      z = Redbus::Stats.bump( "@test1", "failed" )
      z = Redbus::Stats.bump( "@test1", "failed" )
      z = Redbus::Stats.bump( "@test1", "failed" )
      expect(x).to eq(1)
      expect(y).to eq(2)
      expect(z).to eq(3)
    end

    it "can clear channel stats (Use data left from prior test)" do
      count_keys = $busredis.keys( "stats:*" )
      expect(count_keys.length).to eq(3)
      # Clear data left from prior test
      Redbus::Stats.clear( "@test1" )
      count_keys = $busredis.keys( "stats:*" )
      expect(count_keys.length).to eq(0)
    end

    it "can gather stats" do
      load_some_data
      yr = Date.today.year
      mo = Date.today.month
      counts = Redbus::Stats.counts_for( "@test1" )
      expect(counts.length).to eq(3)
      expect(counts["published"][yr][mo]).to eq(1)
      expect(counts["processed"][yr][mo]).to eq(2)
      expect(counts["failed"][yr][mo]).to eq(3)
    end

  end # stats

  def load_some_data
    Redbus::Stats.bump( "@test1", "published" )
    Redbus::Stats.bump( "@test1", "processed" )
    Redbus::Stats.bump( "@test1", "processed" )
    Redbus::Stats.bump( "@test1", "failed" )
    Redbus::Stats.bump( "@test1", "failed" )
    Redbus::Stats.bump( "@test1", "failed" )
  end

end

