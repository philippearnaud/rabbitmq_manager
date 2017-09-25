# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :product_store, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:product_store, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
##
#config :rabbitmq_manager,
#       connection: [
#         username: "guest",
#         password: "guest",
#         host: "localhost"
#       ]

####### CONSUMER KEY : #######

#  workers - (integer) nb of workers to add for the tasks.
#  receive - (module) receiving module implementing consume/1
#  prefetch_count: (integer) limit the number of acknowledged messages to
#  the value given.
#  queues - list of tuples containing declaration of queue. the format of the tuple is
#  {name_of_queue, options}. Queues options are a keyword list and are described below.
#  exchanges - list of tuples containing declaration of each exchange. The format of the tuple
#  is {name_of_exchange, type, options}.
#  - name_of_exchange : (string) whatever is the name of your exchange.
#  - type : (atom)
#    - :topic - Topic exchanges route messages to queues based on wildcard matches between
#    the routing key and something called the routing pattern specified by the queue binding.
#    Messages are routed to one or many queues based on a matching between a message routing key and this pattern.
#    - :fanout - Messages delivered to all queues binded to exchange of this type.
#    - :direct - routing key must be provided with the published message and be setup with the exchange.
# Messages delivered to all queues binded to such exchanges.
#    - :header - Headers exchanges route based on arguments containing headers and optional values.
#     Headers exchanges are very similar to topic exchanges, but it routes based on header values instead of routing keys.
#      A message is considered matching if the value of the header equals the value specified upon binding.
#   bindings - to be routed to queue, a binding must be declared between an exchange and a queue. list of
#   tuples containing declaration of each exchange. The format of the tuple is
#   {queue_name, exchange_name, options}. Options are described below.
#
#  Exchanges options are described below.
#
# QUEUE OPTIONS
#
# :durable (boolean) If set, keeps the Queue between restarts of the broker. Defaults to false.
# :auto-delete (boolean) If set, deletes the Queue once all subscribers disconnect. Defaults to false.
# :exclusive (boolean) If set, only one subscriber can consume from the Queue. Defaults to false.
# :passive (boolean) If set, raises an error unless the queue already exists. Defaults to false.
#
# EXCHANGES OPTIONS
#
# passive: (boolean) Returns an error if the Exchange does not already exist. Defaults to false.
# durable: (boolean) Keeps the exchange between restarts of the broker. Defaults to false.
# auto_delete: (boolean) Delete the exchange once all queues unbind from it. Defaults to false.
# internal: (boolean) The exchange may not be used directly by publishers, but only
# when bound to others exchanges. Internal exchanges are used to construct wiring that is not visible
# to applications. Defaults to false.
#
# BINDINGS OPTIONS
#
# routing_key: Defaults to "".
# arguments: Defaults to [].
# TODO : Raise errors if incompatible setup.
# TODO : if no exchanges
#config :rabbitmq_manager,
#       consumers: [
#         [
#           workers: 2,
#           receive: ProductStore.Consumer,
#           prefetch_count: 35_000,
#           queue: {"product_in_queue", [durable: true]},
#           exchanges: [{"product_in_exchange", :fanout, [durable: true]}],
#           bindings: [
#             {:queue, "product_in_queue", "product_in_exchange", [routing_key: "", arguments: []]}
#           ]
#         ],
#         [
#           workers: 2,
#           receive: ProductStore1.Consumer,
#           prefetch_count: 35_000,
#           queue: {"product_in_queue_2", [durable: true]},
#           exchanges: [
#             {"product_in_exchange_2", :fanout, [durable: true]},
#             {"product_in_exchange_3", :topic, []}
#           ],
#           bindings: [
#             {
#               :queue,
#               "product_in_queue_2",
#               "product_in_exchange_2",
#               [routing_key: "", arguments: []]
#             },
#             {
#               :exchange,
#               "product_in_exchange_2",
#               "product_in_exchange_3",
#               [routing_key: "", arguments: []]
#             }
#           ]
#         ]
#       ]

###### RABBITS MANAGER PRODUCER CONFIG ######
#
# queue : see consumer.
# exchange : see consumer.
# bindings : see consumer.
# confirm_mode : Defauls to false.
# confirm_timeout : Defaults to 5_000 milliseconds.
# publish_options : Keyword list
# - headers list of tuples {name, value}
# - persistent : boolean
# - mandatory : boolean
# - immediate : boolean
#config :rabbitmq_manager,
#       producers: [
#         [
#           key: :product_in,
#           routing_key: "",
#           publish_options: [
#             persistent: false,
#           ],
#           confirm_mode: true,
#           queue: {"product_in_queue", [durable: true]},
#           exchange: {"product_in_exchange", :fanout, [durable: true]},
#           bindings: [
#             {:queue, "product_in_queue", "product_in_exchange", [routing_key: "", arguments: []]}
#           ]
#         ]
#       ]

