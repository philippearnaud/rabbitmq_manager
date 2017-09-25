defmodule RabbitsManager.Config do
  alias RabbitsManager.{ConsumerConfigError, ProducerConfigError, StandardConfigError}
  alias RabbitsManager.Producer.Worker, as: ProducerWorker
  alias RabbitsManager.Consumer.Worker, as: ConsumerWorker
  use AMQP
  require Logger

  def check!() do
    consumer_config = Application.get_env(:rabbits_manager, :consumers)
    producer_config = Application.get_env(:rabbits_manager, :producers)
    _auth_config = Application.get_env(:rabbits_manager, :connection)

    #    cond do
    #      # A consumer or/and producer must be set.
    #      is_nil(consumer_config) and is_nil(producer_config) ->
    #        raise StandardConfigError
    #      # If consumer, one queue in consumer must be set.
    #      !is_nil(consumer_config) && all_consumer_config_has_queue? ->
    #        raise ConsumerConfigError, {"queue", "nil"}
    #      # At least one exchange in consumer must be set.
    #      !is_nil(consumer_config) && is_nil(Keyword.get(consumer_config, :exchanges)) ->
    #        raise ConsumerConfigError, {"exchange", "nil"}
    #      # At least one queue must be set in producer.
    #      !is_nil(producer_config) && is_nil(Keyword.get(producer_config, :queue)) ->
    #        raise ProducerConfigError, {"queue", "nil"}
    #      # At least one exchange must be set in producer.
    #      !is_nil(producer_config) && is_nil(Keyword.get(producer_config, :exchanges)) ->
    #        raise ProducerConfigError, {"exchange", "nil"}
    #      true ->
    #        nil
    #    end
  end

  @spec all_consumer_config_has_queue?() :: boolean
  def all_consumer_config_has_queue?() do
    consumer_params()
    |> Enum.all?(
         fn (consumer) ->
           !is_nil(consumer[:queue])
         end
       )
  end

  @spec connection_params() :: list()
  def connection_params() do
    Application.fetch_env!(:rabbits_manager, :connection)
  end

  @spec consumer_params() :: list()
  def consumer_params() do
    Application.get_env(:rabbits_manager, :consumers, [])
  end

  @spec producer_params() :: list()
  def producer_params() do
    Application.get_env(:rabbits_manager, :producers, [])
  end

  @spec consumer_workers_number() :: integer
  def consumer_workers_number() do
    consumer_config = consumer_params()
    case Keyword.get(consumer_config, :workers) do
      nil -> 1
      value -> value
    end
  end

  @spec create_consumers_supervised_specs() :: map()
  def create_consumers_supervised_specs() do
    consumer_params()
    |> Enum.reduce(
         [],
         fn (consumer_pattern, acc) ->
           acc ++ create_consumer_specs_from_pattern(consumer_pattern)
         end
       )
  end

  @spec create_consumer_specs_from_pattern(list()) :: list()
  def create_consumer_specs_from_pattern(consumer_pattern) do
    1..consumer_pattern[:workers]
    |> Enum.map(
         fn (counter) ->
           %{
             id: String.to_atom("#{consumer_pattern[:receive]}_consumer_worker_#{counter}"),
             start: {ConsumerWorker, :start_link, [consumer_pattern]},
             restart: :permanent,
             shutdown: 5_000,
             type: :worker
           }
         end
       )
  end

  @spec create_producers_supervised_specs() :: map()
  def create_producers_supervised_specs() do
    producer_params()
    |> Enum.map(
         fn (producer_pattern) ->
           %{
             id: String.to_atom("#{producer_pattern[:key]}_producer_worker"),
             start: {ProducerWorker, :start_link, [producer_pattern]},
             restart: :permanent,
             shutdown: 5_000,
             type: :worker
           }
         end
       )
  end

  @spec declare_queue_and_exchanges(atom(), %AMQP.Channel{}, list()) :: nil
  def declare_queue_and_exchanges(type, channel, state) do
    case type do
      :consumer ->
        channel
        |> declare_qos(state[:prefetch_count])
        |> declare_queue(state[:queue])
        |> declare_exchanges(state[:exchanges])
        |> declare_bindings(state[:bindings])
      :producer ->
        channel
        |> declare_queue(state[:queue])
        |> declare_exchanges(state[:exchange])
        |> declare_bindings(state[:bindings])
    end
  end

  @spec declare_qos(%AMQP.Channel{}, integer()) :: %AMQP.Channel{}
  defp declare_qos(channel, prefetch_count) do
    Basic.qos(channel, prefetch_count: prefetch_count)
    channel
  end

  @spec declare_queue(%AMQP.Channel{}, list()) :: %AMQP.Channel{}
  defp declare_queue(channel, queue) do
    Queue.declare(channel, elem(queue, 0), elem(queue, 1))
    Logger.info "#{__MODULE__} Queue #{elem(queue, 0)} declared in #{inspect channel}"
    channel
  end

  @spec declare_exchanges(%AMQP.Channel{}, list()) :: %AMQP.Channel{}
  defp declare_exchanges(channel, []), do: channel
  defp declare_exchanges(channel, [h | t]) do
    Exchange.declare(channel, elem(h, 0), elem(h, 1), elem(h, 2))
    Logger.info "#{__MODULE__} Exchange #{elem(h, 0)} declared in #{inspect channel}"
    declare_exchanges(channel, t)
  end
  defp declare_exchanges(channel, exchange) when is_tuple(exchange) do
    Exchange.declare(channel, elem(exchange, 0), elem(exchange, 1), elem(exchange, 2))
    Logger.info "#{__MODULE__} Exchange #{elem(exchange, 0)} declared in #{inspect channel}"
    channel
  end

  @spec declare_bindings(%AMQP.Channel{}, list()) :: %AMQP.Channel{}
  defp declare_bindings(_channel, []), do: nil
  defp declare_bindings(channel, [h | t]) do
    case elem(h, 0) do
      :queue ->
        Queue.bind(channel, elem(h, 1), elem(h, 2), elem(h, 3))
      :exchange ->
        Exchange.bind(channel, elem(h, 1), elem(h, 2), elem(h, 3))
      _ ->
        nil
    end
    Logger.info "#{__MODULE__} Binding #{inspect elem(h, 0)} - #{elem(h, 1)} declared in #{inspect channel}"
    declare_bindings(channel, t)
  end
end
