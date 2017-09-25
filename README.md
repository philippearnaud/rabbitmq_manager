# Rabbitmq Manager 

Rabbitmq Manager aims to allow from easy to complex rabbitMQ settings in elixir following 
RabbitsMQ best practices. Based on amqp and amqp_client.

## Installation

The package can be installed
by adding `rabbitmq_manager` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rabbitmq_manager, "~> 0.1.0"}
  ]
end
```


## Configuration

You must provide three keys in configuration files to get started. If you use consumers, you
must provide a receive module which will handle the received payload.

### Configuration keys setup

#### Connection key 

As AMQP.Connection.open() is used, this is the same options. Here is the documentation
from the lib amqp.

- `:username` - The name of a user registered with the broker (defaults to \"guest\");
- `:password` - The password of user (defaults to \"guest\");
- `:virtual_host` - The name of a virtual host in the broker (defaults to \"/\");
- `:host` - The hostname of the broker (defaults to \"localhost\");
- `:port` - The port the broker is listening on (defaults to `5672`);
- `:channel_max` - The channel_max handshake parameter (defaults to `0`);
- `:frame_max` - The frame_max handshake parameter (defaults to `0`);
- `:heartbeat` - The hearbeat interval in seconds (defaults to `0` - turned off);
- `:connection_timeout` - The connection timeout in milliseconds (defaults to `infinity`);
- `:ssl_options` - Enable SSL by setting the location to cert files (defaults to `none`);
- `:client_properties` - A list of extra client properties to be sent to the server, defaults to `[]`;
- `:socket_options` - Extra socket options. These are appended to the default options. \
                          See http://www.erlang.org/doc/man/inet.html#setopts-2 and http://www.erlang.org/doc/man/gen_tcp.html#connect-4 \
                          for descriptions of the available options.

To enable SSL, supply the following in the `ssl_options` field:

* `cacertfile` - Specifies the certificates of the root Certificate Authorities that we wish to implicitly trust;
* `certfile` - The client's own certificate in PEM format;
* `keyfile` - The client's private key in PEM format;


```elixir
config :rabbitmq_manager,
       connection: [
         username: "my_username",
         password: "my_password",
         host: "my_host"
       ]
```

#### Consumers key

- `:workers` - (integer) nb of workers to add for the tasks.
- `:receive` - (module) receiving module implementing consume/1
- `:prefetch_count` - (integer) limit the number of acknowledged messages to
 the value given.
- `:queues` - list of tuples containing declaration of queue. the format of the tuple is
  {name_of_queue, options}. Queues options are a keyword list and are described below.
  exchanges - list of tuples containing declaration of each exchange. The format of the tuple
  is {name_of_exchange, type, options}.
  - `:name_of_exchange` : (string) whatever is the name of your exchange.
  - `:type` : (atom)
    - :topic - Topic exchanges route messages to queues based on wildcard matches between
    the routing key and something called the routing pattern specified by the queue binding.
    Messages are routed to one or many queues based on a matching between a message routing key and this pattern.
    - :fanout - Messages delivered to all queues binded to exchange of this type.
    - :direct - routing key must be provided with the published message and be setup with the exchange.
 Messages delivered to all queues binded to such exchanges.
    - :header - Headers exchanges route based on arguments containing headers and optional values.
     Headers exchanges are very similar to topic exchanges, but it routes based on header values instead of routing keys.
      A message is considered matching if the value of the header equals the value specified upon binding.
   bindings - to be routed to queue, a binding must be declared between an exchange and a queue. list of
   tuples containing declaration of each exchange. The format of the tuple is
   {queue_name, exchange_name, options}. Options are described below.

 Exchanges options are described below.

 QUEUE OPTIONS

- `:durable` (boolean) If set, keeps the Queue between restarts of the broker. Defaults to false.
- `:auto-delete` (boolean) If set, deletes the Queue once all subscribers disconnect. Defaults to false.
- `:exclusive` (boolean) If set, only one subscriber can consume from the Queue. Defaults to false.
- `:passive` (boolean) If set, raises an error unless the queue already exists. Defaults to false.

 EXCHANGES OPTIONS

- `:passive` (boolean) Returns an error if the Exchange does not already exist. Defaults to false.
- `:durable` (boolean) Keeps the exchange between restarts of the broker. Defaults to false.
- `:auto_delete` (boolean) Delete the exchange once all queues unbind from it. Defaults to false.
- `:internal` (boolean) The exchange may not be used directly by publishers, but only
 when bound to others exchanges. Internal exchanges are used to construct wiring that is not visible
 to applications. Defaults to false.

 BINDINGS OPTIONS

- `:routing_key` Defaults to "".
- `:arguments` Defaults to [].
 
 Here is an example : 
 ```elixir
 config :rabbitmq_manager,
        consumers: [
          [
            workers: 2,
            receive: ProductStore.Consumer,
            prefetch_count: 35_000,
            queue: {"product_in_queue", [durable: true]},
            exchanges: [{"product_in_exchange", :fanout, [durable: true]}],
            bindings: [
              {:queue, "product_in_queue", "product_in_exchange", [routing_key: "", arguments: []]}
            ]
          ],
          [
            workers: 2,
            receive: ProductStore1.Consumer,
            prefetch_count: 35_000,
            queue: {"product_in_queue_2", [durable: true]},
            exchanges: [
              {"product_in_exchange_2", :fanout, [durable: true]},
              {"product_in_exchange_3", :topic, []}
            ],
            bindings: [
              {
                :queue,
                "product_in_queue_2",
                "product_in_exchange_2",
                [routing_key: "", arguments: []]
              },
              {
                :exchange,
                "product_in_exchange_2",
                "product_in_exchange_3",
                [routing_key: "", arguments: []]
              }
            ]
          ]
        ]
```

#### Producers key

- `:queue` : (tuple) consumer.
- `:exchange` : (tuple) see consumer.
- `:bindings` : (list) see consumer.
- `:confirm_mode` : Defaults to false.
- `:confirm_timeout` : Defaults to 5_000 milliseconds.
- `:publish_options` : Keyword list
  - headers list of tuples {name, value}
  - persistent : (boolean) Defaults to false.
  - mandatory : (boolean) Defaults to false.
  - immediate : (boolean) Defaults to false.


### Receiving module for consumers

Each pattern of consumers must provide a receiving module which will handle the payload.

Here is how consuming is implemented :
```elixir
  defp consume(channel, tag, redelivered, payload, state) do
    case apply(state[:receive], :receive, [payload]) do
      :ok ->
        Basic.ack channel, tag
      :error ->
        Basic.reject channel, tag, requeue: false
    end
  rescue
    # We requeue unless redelivered message.
    exception ->
      Basic.reject channel, tag, requeue: not redelivered
      Logger.warn "#{inspect exception}"
  end
```

Here is an example of a receive function in a receiving module.
```elixir
defmodule ReceivingModule do

 def receive(payload) do
    # Code that handle the payload.
    # If ok, must return :ok
    # If any errors while processing the payload, must return :error.
    # If any exceptions, do not catch.
 end
end
```