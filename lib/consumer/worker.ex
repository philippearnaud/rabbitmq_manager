defmodule RabbitsManager.Consumer.Worker do
  require Logger
  use GenServer
  use AMQP

  alias RabbitsManager.{ConnectionManager, Config}
  # TODO : Check if consumer tag is needed.

  def start_link(consumer_pattern) do
    GenServer.start_link(__MODULE__, consumer_pattern)
  end

  ### 1. CONNECTION STUFF ###
  ### WE MUST NOT INITIALIZE CONNECTION IN INIT OF A SUPERVISED PROCESS
  ### CAUSE IT WILL IMPACT STABILITY OF THE SYSTEM.
  ### RESTARTING A PROCESS IS ABOUT BRINGINT IT BACK TO A STABLE STATE.
  def init(state) do
    Process.send(self(), :init_consumer, [])
    {:ok, state}
  end

  ##### 2. GenServer callbacks ####
  def handle_info(:init_consumer, state) do
    new_state = init_consumer(state)
    {:noreply, new_state}
  end

  def init_consumer(state) do
    connection_result = ConnectionManager.get_connection()
    new_state = case connection_result do
      {:ok, connection} ->
        {:ok, channel} = setup_consumer_config(state, connection)
        Logger.info "#{__MODULE__} : Channel established with RabbitMQ server"
        Keyword.merge(state, [connection: connection, channel: channel])
      {:error, :not_connected} ->
        Logger.warn "#{__MODULE__} : Channel could not be established. Waiting for connection."
        Process.send_after(self(), :init_consumer, 10_000)
        state
    end
  end

  def setup_consumer_config(state, connection) do
    {:ok, channel} = Channel.open(connection)
    Config.declare_queue_and_exchanges(:consumer, channel, state)
    register_server_process_as_consumer(channel, state[:queue], state, 0)
    {:ok, channel}
  end

  defp register_server_process_as_consumer(channel, queue, state, counter) do
    {:ok, consumer_tag} = Basic.consume(channel, elem(queue, 0), nil, [consumer_tag: "#{state[:receive]}@#{counter}"])
    Logger.info "#{consumer_tag} consumer correctly registered"
  end

  # Confirmation sent by the broker after registering the process as a consumer.
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, state) do
    Logger.info "Basic_consume_ok"
    {:noreply, state}
  end

  # Sent by the broker when the consumer is unexpectedly canceled.
  # eg : in case of queue deletion.
  def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, state) do
    Logger.error "#{consumer_tag} : basic_cancel"
    {:stop, :normal, state}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered, consumer_tag: consumer_tag}},
        state
      ) do
    Logger.info "#{consumer_tag} : basic_deliver"
    consume(state[:channel], tag, redelivered, payload, state)
    {:noreply, state}
  end

  defp consume(channel, tag, redelivered, payload, state) do
    try do
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
    end
  end
end