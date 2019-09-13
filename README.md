# Redbus

<p align="center"><div align="center">

![Red Bus](redbus.jpg)

</div></p>

Redbus is a Redis-based message bus that uses Redis's LIST mechanism to push and pop messages onto queues. The advantage of this over it's native PUB/SUB is that in a clustered deployment you only want **one** endpoint server for a channel to accept a message. The normal PUB/SUB would have each endpoint server in the cluster see and respond to each message.

## Features

- Fan-out for interest-based channels
- RPC mode calls which are blocking and wait for a return value
- Central registration of channels and subscriptions
- Twitter-esque channel namespace to differentiate "endpoints" from "interests"
- Uses BLPOP so that only one server in an app cluster processes a message
- Redis-based inter-service comms means no security issues, no authentication hassles, and no possibility for exposed HTTP endpoints
- Simple on-board stats to monitor overall health of the bus

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redbus'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redbus

## Usage

TODO: Write usage instructions here

***Basic use case***
```ruby
# Rig a callback
class Kallback
  def self.dump(*args)
    x = { :channel => args[0], :data => args[1] }
    ap x
  end
end

# Rig Redis - you need different connections for pub and sub
$redis = Redis.new
$pubredis = Redis.new
$subredis = Redis.new

# Set the app's endpoint
Redbus.endpoint = "my_endpoint"

# Register the endpoint
Redbus::Registration.register_endpoint
# Register interests
Redbus::Registration.register_interest('#users')
Redbus::Registration.register_interest('#views')

# Bulk subscribe to everything registered for
Redbus::Lpubsub.subscribe_all( "Kallback::dump" )
```

***Stats***

To gather the `published`, `processed`, and `failed` stats for a channel you do the following:

```
counts = Redbus::Stats.counts_for( "@test1" )
p counts['published'] # =>
{
  2019 => {
    8 => 12,
    9 => 2
  }
}
```
## Configuration

In `.../config/initializers/redbus.rb` you can set the following:

```ruby
# Required
Redbus.endpoint = "my_endpoint"     # Unique name for your app's endpoint
                                    # Note: the '@' prefix isn't required
# Optional
Redbus.poll_delay = 0               # Delay between Redis polls(ms)
Redbus.timeout = 5                  # Timeout on 1-shot subscribes(s)
```

_Note that you can have multiple endpoints for a microservice. For instance you could have one for `@email` and one for `@sms`. But at the end of the day there isn't much gain. All you're doing is going from one callback with a switch to two callbacks. So for simplicity sake, just assume one primary endpoint name per app._

## Channel Namespaces

Redbus uses a Twitter-esque namespace pattern:

`@channel` - this is an "endpoint", used for sending a message to a specific microservice. For instance, @email would be what an email service subscribes to and what a client would send to in order to send an email.

`#channel` - this is for "interests". For instance, an email service would want to know about Agents and Offices to be able to find mail templates, so it would subscribe to [#agents, #offices] to be notified of any updates.

`rpc.XXXXXXXXXXXXXXXX` - these are ad-hoc channels used for waiting for and sending RPC-like responses to requests. The channel name is created by MagicBus and destroyed once the round-trip is complete.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/redbus. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Redbus project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/redbus/blob/master/CODE_OF_CONDUCT.md).
