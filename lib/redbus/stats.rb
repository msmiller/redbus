#!/usr/bin/ruby
# @Author: msmiller
# @Date:   2019-09-12 20:42:13
# @Last Modified by:   msmiller
# @Last Modified time: 2019-10-29 16:01:39
#
# Copyright (c) Sharp Stone Codewerks / Mark S. Miller

# This module saves stats for sent, received, and errors for each channel. Just basic
# stuff so it's possible to monitor how the bus is doing in braod strokes.
# The data is housed as:
#
# stats:{channel}:year:month:[published, processed, failed]
#
# NOTE: I'm not using the Redis hash here since we're mainly concerned with
# storage speed, not with dumping results for some console.

require 'date'

module Redbus
  class Stats

    BUCKET_NAMES = [ 'published', 'processed', 'failed' ]

    # Bump a counter for 'published', 'processed', or 'failed'
    def self.bump(channel, bucket)
      yr = Date.today.year
      mo = Date.today.month
      stats_key = "stats:#{channel}:#{bucket}:#{yr}:#{mo}"
      # ap stats_key
      $busredis.incr(stats_key)
    end

    def self.counts_for(channel)
      count_keys = $busredis.keys( "stats:#{channel}:*" )
      result = {}
      count_keys.each do |k|
        ignore1,ignore2,bucket,yr,mo = k.split(":")
        result[bucket] ||= {}
        result[bucket][yr.to_i] ||= {}
        result[bucket][yr.to_i][mo.to_i] = $busredis.get(k).to_i
      end
      return result
    end

    def self.clear(channel)
      count_keys = $busredis.keys( "stats:#{channel}:*" )
      count_keys.each { |k| $busredis.del(k) }
    end

  end
end
