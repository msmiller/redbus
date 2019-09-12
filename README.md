# Redbus

<center>
    ![alt text](redbus.jpg){ style="display: block; margin: 0 autol border: 1px solid #ccc; border-radius: 10px;" }
</center>

Redbus is a Redis-based message bus that uses Redis's LIST mechanism to push and pop messages onto queues. The advantage of this over it's native PUB/SUB is that in a clustered deployment you only want **one** endpoint server for a channel to accept a message. The normal PUB/SUB would have each endpoint server in the cluster see and respond to each message.

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

## Configuration

In `.../config/initializers/redbus.rb` you can set the following:

```
Redbus.endpoint = "my_endpoint"     # Unique name for your app's endpoint
Redbus.poll_delay = 0               # Delay between Redis polls(ms)
Redbus.timeout = 5                  # Timeout on 1-shot subscribes(s)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/redbus. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Redbus project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/redbus/blob/master/CODE_OF_CONDUCT.md).
