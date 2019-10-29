# Redbus

<p align="center"><div align="center">

![](redbus.jpg)

</div></p>

Redbus is a Redis-based message bus that uses Redis's LIST mechanism to push and pop messages onto queues. The advantage of this over it's native PUB/SUB is that in a clustered deployment you only want **one** endpoint server for a channel to accept a message. The normal PUB/SUB would have each endpoint server in the cluster see and respond to each message.

----

<!-- https://ecotrust-canada.github.io/markdown-toc/ -->

- [Redbus](#redbus)
    - [Features](#features)
    - [Installation](#installation)
    - [Channel Namespaces](#channel-namespaces)
    - [Usage](#usage)
    - [Configuration (Running in a thread within a Rails -pp)](#configuration--running-in-a-thread-within-a-rails-app-)
    - [Running as a standalone daemon](#running-as-a-standalone-daemon)
    - [RPC](#rpc)
    - [Cache-Thru](#cache-thru)
    - [Stats](#stats)

----

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

***Important: Connecting To Redis***

All Apps and services which use Redbus must connect to the same Redis server. This means you're going to have one Redis server for your code to use for background processing, and another you connect to for the message bus. The way Redis' pub/sub mechanism works, you need different connections for publish and subscribe. The pattern adopted for Redbus is to maintain three permanent connections: 

- One for publushing
- One for subscribing
- One for management, registration and statistics gathering

```ruby
$busredis = Redis.new
$pubredis = Redis.new
$subredis = Redis.new
```

## Channel Namespaces

Redbus uses a Twitter-esque namespace pattern to make it easier to visualize message flow:

`@channel` - this is an "endpoint", used for sending a message to a specific microservice. For instance, @email would be what an email service subscribes to and what a client would send to in order to send an email. Sending to a `@channel` is a 1-to-1 message delivery - only one app/service will respond to the message and only one worker on that app/service will process the message.

`#channel` - this is for "interests". For instance, an email service would want to know about Agents and Offices to be able to find mail templates, so it would subscribe to [#agents, #offices] to be notified of any updates. Sending to a `#channel` delivers the message to every app/service that is subscribed. Only one worker on a subscribed app/service will process the message.

`rpc.XXXXXXXXXXXXXXXX` - these are ad-hoc channels used for waiting for and sending RPC-like responses to requests. The channel name is created by MagicBus and destroyed once the round-trip is complete.

## Usage

Redbus can run as either an initializer within a Rails app, or as a standalone worker process.

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
$busredis = Redis.new
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
Redbus::Lpubsub.subscribe_all( true, "Kallback::dump" )
```

More detailed configuration and integration examples are included later in this README.

## Configuration (Running in a thread within a Rails App)

**NOTE:** _The initializer needs to be called `redis_bus.rb` so that it loads after `redis.rb`._

In `.../config/initializers/redis_bus.rb` you can set the configuration and the subscriptions. You then put your handler model in `.../lib`,

```ruby
# .../config/initializers/redis_bus.rb

# Instantiate publish and subscribe Redis connections
$busredis = Redis.new
$pubredis = Redis.new
$subredis = Redis.new

# Required
Redbus.endpoint = "my_endpoint"     # Unique name for your app's endpoint
                                    # Note: the '@' prefix isn't required
# Optional
Redbus.poll_delay = 1               # Delay between Redis polls (s)
Redbus.timeout = 5                  # Timeout on 1-shot subscribes (s)

# Register defined endpoint and interests
Redbus::Registration.register_endpoint
Redbus::Registration.register_interest("#posts")
Redbus::Registration.register_interest("#users")

# Now set up the listener, which runs in a backround thread
Redbus.subscribe_async( 
    Redbus::Registration.subscribe_list,
    true, # threaded mode is set
    "RedbusHandler::perform"
)
```

Then set up your handler:

```ruby
# .../lib/redbus_handler.rb
class RedbusHandler

  def self.perform(*args)
    channel,payload = args

    case channel
    when "@#{Redbus.endpoint}"
      handle_endpoint(payload)
    when '#posts'
      handle_posts(payload)
    when '#users'
      handle_users(payload)
    else
      # Throw and error or something ...
    end
  end

end
```

_Note that you can have multiple endpoints for a microservice. For instance you could have one for `@email` and one for `@sms`. But at the end of the day there isn't much gain. All you're doing is going from one callback with a switch to two callbacks. So for simplicity sake, just assume one primary endpoint name per app._

## Running as a standalone daemon 

To run Redbus as a standalone process is basically just taking some of the initializer and moving it to a standalone script, with a few small changes. This example assumes the same `RedbusHandler` is available. 

```ruby
# .../config/initializers/redis_bus.rb

$busredis = Redis.new
$pubredis = Redis.new
$subredis = Redis.new

Redbus.endpoint = "my_endpoint"
Redbus.poll_delay = 0
Redbus.timeout = 5
```

Here's the worker, which gets run as `bundle exec ruby run_redbus.rb`:

```ruby
# .../run_redbus.rb
#
# USAGE: bundle exec ruby run_redbus.rb

require 'redis'
require 'redbus'

# Register defined endpoint and interests
# 
# When running as a daemon, only the daemon cares about these
# registrations. So they're no longer needed in the main
# initializer.
Redbus::Registration.register_endpoint
Redbus::Registration.register_interest("#posts")
Redbus::Registration.register_interest("#users")

# Now run the listener with threaded mode OFF
begin
  Redbus.subscribe_async( 
      Redbus::Registration.subscribe_list,
      false, # threaded mode is OFF
      "RedbusHandler::perform"
  )
rescue Interrupt => e
  print_exception(e, true)
  $busredis.close
  $pubredis.close
  $subredis.close
end
```

## RPC

Redbus supports making RPC calls across the bus. On the sending side, the following is all that is needed to send an RPC request with a payload to an endpoint (_NOTE: RPC only works to endpoints!_).

```ruby
rpc_result = Redbus::Rpc.publish_rpc( "@channel", { "command" => "do_something", "foo" => "bar" } )
```

In your receiving App or Service, you need to handle the request in your handler and perform the following to send back a response:

```ruby
# .../lib/redbus_handler.rb
class RedbusHandler

  def self.perform(*args)
    channel,payload = args
    parsed_payload = JSON.parse(payload)

    case channel
    when "@#{Redbus.endpoint}"
      if parsed_payload['rpc_token']
        # This is an RPC request
        result = { ack: 'oop' }.to_json
        $pubredis.publish parsed_payload['rpc_token'], result
      else
        handle_endpoint(parsed_payload)
      end
    when '#posts'
      # ...
    when '#users'
      # ...
    else
      # Throw and error or something ...
    end
  end

end
```

You can use whatever mechanism you like to encode what you want the RPC call to perform on the receiving end. Returned results can likewise be anything you want, from a simple pass/fail status to complex data objects.

The request times out after `Redbus.timeout` seconds, so this isn't to be used for long-duration requests unless they are to put a job into the background and return a job id so it can be checked on with another RPC call.

The intent here is not to impose a message format, but to provide the transport needed to create more complex interactions.

## Cache-Thru

Another feature of Redbus is the ability to use Redis as a temporary object cache for data which is only needed temporarily, or which doesn't need persistence in the main database. An example use case is where you have a remote scheduling service that manages some kind of appointments database and you want to display upcoming appointments in user-facing App. In this case you want the appointments localized to the App to avoid repeated calls to the service, but you don't need them persisted much past their date/time.

It's called as follows:

```ruby
cachethru_result = Redbus::Cachethru.retrieve(
                    'Frodus', # Object class
                    5678,     # Object ID
                    "@test"   # Channel (endpoints only!)
                   )
```

The `retrieve` call checks if the object is already in the Redis cache and if it isn't it makes an RPC call to  the `@channel` to get it.

On the receiving end, you do the following to return the object via Redis:

```ruby
class RedbusHandler

  def self.perform(*args)
    channel,payload = args
    parsed_payload = JSON.parse(payload)

    channel,payload = args
    f = Frodus.find(parsed_payload['item_id'])
    Redbus::Cachethru.deposit(f, parsed_payload['rpc_token'])
  end

end
```

You can also specify an expiration and an alternate representation. Say for instance you want to Cache-Thru User records, you don't want sensitive information going out. So with these options the call would look like:

```ruby
class RedbusHandler

  def self.perform(*args)
    channel,payload = args
    parsed_payload = JSON.parse(payload)

    channel,payload = args
    f = Frodus.find(parsed_payload['item_id'])
    json_info = { 'name' => f.name, 'role' = f.role }.to_json
    Redbus::Cachethru.deposit( f, parsed_payload['rpc_token'], 
                               (Time.now + 10.days),
                               json_info )
  end

end
```

## Stats

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

This can be useful for determining if messages are flowing properly, or monitoring the amount of traffic running through the system.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rspec` to run the tests. 

**NOTE:** You will need to have a proper Redis server running to run Rspec. This mechanism uses more advanced features of Redis and some aren't properly supported on the various Redis emulators.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/msmiller/redbus. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Redbus project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/msmiller/redbus/blob/master/CODE_OF_CONDUCT.md).
