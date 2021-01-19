# Redbus

<p align="center"><div align="center">

![](redbus.jpg)

</div></p>

Redbus is a Redis-based message bus that uses Redis's LIST mechanism to push and pop messages onto queues. The advantage of this over it's native PUB/SUB is that in a clustered deployment you only want **one** endpoint server for a channel to accept a message. The normal PUB/SUB would have each endpoint server in the cluster see and respond to each message.

The intent is to provide a simple and fast mechanism to impliment an inter-app and/or inter-service message bus across a shared Redis instance. This isn't meant to compete with the likes of AWS SQS or RabbitMQ. It's meant to be lean and mean.

----

<!-- https://ecotrust-canada.github.io/markdown-toc/ -->

* [Features](#features)
* [Installation](#installation)
* [Channel Namespaces](#channel-namespaces)
* [Usage](#usage)
* [Options](#options)
* [Running in a thread within a Rails App](#running-in-a-thread-within-a-rails-app)
* [Running as a standalone daemon](#running-as-a-standalone-daemon)
* [RPC](#rpc)
* [Cache-Thru](#cache-thru)
* [Stats](#stats)
* [Development](#development)
* [Testing](#testing)
* [Caveat Emptor](#caveatemptor)


----

## Features

- Fan-out for interest-based channels
- RPC mode calls which are blocking and wait for a return value
- Central registration of channels and subscriptions based on YAML config files
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

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install redbus
```

## Channel Namespaces

Redbus uses a Twitter-esque namespace pattern to make it easier to visualize message flow:

**`@channel`** - this is an "endpoint", used for sending a message to a specific microservice. For instance, @email would be what an email service subscribes to and what a client would send to in order to send an email. Sending to a `@channel` is a 1-to-1 message delivery - only one app/service will respond to the message and only one worker on that app/service will process the message.

**`#channel`** - this is for "interests". For instance, an email service would want to know about Users and Customers to be able to find mail templates, so it would subscribe to [#users, #customers] to be notified of any updates. Sending to a `#channel` delivers the message to every app/service that is subscribed. Only one worker on a subscribed app/service will process the message.

**`rpc.XXXXXXXXXXXXXXXX`** - these are ad-hoc channels used for waiting for and sending RPC-like responses to requests. The channel name is created by Redbus and destroyed once the round-trip is complete.

## Usage

Redbus can run as either an initializer within a Rails app, or as a standalone worker process.

***Basic use case***

```ruby
@yaml_file = 'redbus_topology.yml' # from .../config
@endpoint = 'test1'
@redis_url = 'redis://:p4ssw0rd@10.0.1.1:6380/15'
# Instantiate a new RedBus
@current_redbus = RedBus.new(@endpoint, @yaml_file, @redis_url)

# Bulk subscribe to everything registered for in the yaml config
# The first argument determines if this is running async in a thread
# or inline as a daemon. The second argument is the callback for 
# processing incoming messages
@current_redbus.subscribe_all( true, "Kallback::dump")
```

_Note that the shared Redis instance is passed in as the third argument. If you're running locally in development mode, you can leave this off use Redbus will use the default configuration for the local Redis instance._

And you need a callback to process requests:

```ruby
# Rig a callback
class Kallback
  def self.dump(*args)
    x = { :channel => args[0], :data => args[1] }
    ap x
  end
end
```

Then you need a YAML Configuration:

```yaml
test1:
  interests:
    - interest1
    - interest2
test2:
  interests:
    - interest2
    - interest3
test3:
  interests:
```

And that's basically it!

## Options

These can be changed after initialization as:

```ruby
@current_redbus.option = value
```

**gather_stats** - The RedBus instance will gather statistics (default: false)

**poll_delay** - This throttles how often to ping Redbus when it's empty (default: 1s)

**timeout** - This is the timeout for single-use subscriptions (default: 5s)

## Running in a thread within a Rails App

**NOTE:** _The initializer needs to be called `redis_bus.rb` so that it loads after `redis.rb`._

In `.../config/initializers/redbus.rb` you can set the configuration and the subscriptions. You then put your handler model in `.../lib`,

```ruby
# .../config/initializers/redbus.rb

@yaml_file = 'redbus_topology.yml' # from .../config
@endpoint = 'test1'
@redis_url = 'redis://:p4ssw0rd@10.0.1.1:6380/15'
# Instantiate a new RedBus
@current_redbus = RedBus.new(@endpoint, @yaml_file, @redis_url)

# Bulk subscribe to everything registered for in the yaml config
# The first argument determines if this is running async in a thread
# or inline as a daemon. The second argument is the callback for 
# processing incoming messages
@current_redbus.subscribe_all( true, "RedbusHandler::perform" )
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

_Note that you can have multiple RedBus instances running for different endpoints in the same app._

## Running as a standalone daemon 

To run Redbus as a standalone process is basically just taking the initializer and moving it to a standalone script, with a few small changes. This example assumes the same `RedbusHandler` is available. 

```ruby
# .../run_redbus.rb
#
# USAGE: bundle exec ruby run_redbus.rb

require 'redis'
require 'redbus'

@yaml_file = 'redbus_topology.yml' # from .../config
@endpoint = 'test1'
@redis_url = 'redis://:p4ssw0rd@10.0.1.1:6380/15'
# Instantiate a new RedBus
@current_redbus = RedBus.new(@endpoint, @yaml_file, @redis_url)

# Now run the listener with threaded mode OFF
begin
  @current_redbus.subscribe_all( false, "RedbusHandler::perform" )
rescue Interrupt => e
  print_exception(e, true)
  @current_redbus.close_redis
end

def print_exception(exception, explicit)
    puts "[#{explicit ? 'EXPLICIT' : 'INEXPLICIT'}] #{exception.class}: #{exception.message}"
    puts exception.backtrace.join("\n")
end
```

## RPC

Redbus supports making RPC calls across the bus. For these commands Redbus synthesizes a temporary RPC channel and sends a request to the desired endpoint which includes that channel name as the channel to respond to. The receiving Redbus handler detects and RPC requests, forms a response and publish to the RPC channel that the original sender is listening and waiting on. Once it gets the RPC response it unblocks and code flows as normal - pretty much like with an HTTP request.

On the sending side, the following is all that is needed to send an RPC request with a payload to an endpoint (_NOTE: RPC only works to endpoints!_).

```ruby
rpc_result = @current_redbus.publish_rpc( 
  "@channel", 
  { "command" => "do_something", 
    "foo" => "bar"
  }
)
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
        @current_redbus.publish parsed_payload['rpc_token'], result
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

The request times out after `@current_redbus.timeout` seconds, so this isn't to be used for long-duration requests unless they are to put a job into the background and return a job id so it can be checked on with another RPC call.

The intent here is not to impose a message format, but to provide the transport needed to create more complex interactions.

## Cache-Thru

Another feature of Redbus is the ability to use Redis as a temporary object cache for data which is only needed temporarily, or which doesn't need persistence in the main database. An example use case is where you have a remote scheduling service that manages some kind of appointments database and you want to display upcoming appointments in user-facing App. In this case you want the appointments localized to the App to avoid repeated calls to the service, but you don't need them persisted much past their date/time.

It's called as follows:

```ruby
cachethru_result = @current_redbus.retrieve(
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
    @current_redbus.deposit(f, parsed_payload['rpc_token'])
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
    @current_redbus.deposit( f, parsed_payload['rpc_token'], 
                               (Time.now + 10.days),
                               json_info )
  end

end
```

## Stats

To gather the `published`, `processed`, and `failed` stats for a channel you do the following:

```ruby
@current_redbus.gather_stats = true
# ... do some redbus stuff ...
counts = @current_redbus.counts_for( "@test1" )
p counts['published'] # =>
{
  2019 => {
    8 => 12,
    9 => 2
  }
}
```

This can be useful for determining if messages are flowing properly, or monitoring the amount of traffic running through the system.

_NOTE: By default stats gathering is switched off for new RedBus instances. To switch it on:_ `@current_redbus.gather_stats = true`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rspec` to run the tests. 

**NOTE:** You will need to have a proper Redis server running to run Rspec. This mechanism uses more advanced features of Redis and some aren't properly supported on the various Redis emulators.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Testing

Because Redbus relies on Redis to act like ... well ... Redis the Rspec code doesn't use a Redis emulator. This was tried and while the API calls all worked, the actual behavior wasn't consistent with an actual live server.

So to test this gem you need to run `redis-server` in another process before calling Rspec. Note that Rspec will flush what's in this Redis instance repeatedly, so make sure you run `redis-server` in a different/throw-away directory so as not to clobber data you may care about.

## Caveat Emptor

I am by no means a Redis expert. This project was something I spun up when a client was having issues with using straight HTTP/RPC for a large microservice-based  deployment. Once I got into it, I found all these other cool things it could do. But it's entirely possible there's stuff in here which is rock-stupid to folks who are more expert. I won't be offended in the least if someone else can show me smarter ways to code pieces of this up.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/msmiller/redbus. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Redbus project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/msmiller/redbus/blob/master/CODE_OF_CONDUCT.md).

----

Copyright &copy; <a href="https://github.com/msmiller">Mark S. Miller</a> and <a href="http://sharpstonecodewerks.com">Sharp Stone Codewerks</a>

