defmodule RabbitsManager.Consumer.Worker do
  @moduledoc """
  Consumer Worker.

  A consumer worker is started with a consumer_pattern as arguments wich is all
  informations defined in config file for the given consumers.
  """
  require Logger
  use GenServer
  use AMQP

  alias RabbitsManager.{ConnectionManager, Config}

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

  @spec init_consumer(list) :: list()
  def init_consumer(state) do
    # We link the connection process to the worker one to be notified when down.
    :rmq_connection_manager
    |> GenServer.whereis()
    |> Process.monitor()
    # We get the connection
    connection_result = ConnectionManager.get_connection()
    case connection_result do
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

  @spec consume(%Channel{}, any(), any(), String.t, list) :: any()
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

  @spec setup_consumer_config(list(), %Connection{}) :: {:ok, %Channel{}}
  def setup_consumer_config(state, connection) do
    {:ok, channel} = Channel.open(connection)
    Config.declare_queue_and_exchanges(:consumer, channel, state)
    non_error_queue = if (is_list(state[:queues])), do: List.last(state[:queues]), else: state[:queues]
    register_server_process_as_consumer(channel, non_error_queue, state)
    {:ok, channel}
  end

  @spec register_server_process_as_consumer(%Channel{}, tuple(), list()) :: {:ok, any}
  defp register_server_process_as_consumer(channel, queue, state) do
    {:ok, consumer_tag} = Basic.consume(
      channel,
      elem(queue, 0),
      nil,
      [consumer_tag: "#{state[:receive]}@#{state[:counter]}"]
    )
    Logger.info "#{consumer_tag} consumer correctly registered"
    {:ok, consumer_tag}
  end

  ##### 2. GenServer callbacks ####
  # If system down, then crash.
  def handle_info({:DOWN, _, :process, _pid, _reason}, state)  do
    {:stop, :normal, state}
  end

  def handle_info(:init_consumer, state) do
    new_state = init_consumer(state)
    {:noreply, new_state}
  end

  # Confirmation sent by the broker after registering the process as a consumer.
  def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, state) do
    Logger.info "#{consumer_tag} : Basic_consume_ok"
    {:noreply, state}
  end

  # Sent by the broker when the consumer is unexpectedly canceled.
  # eg : in case of queue deletion.
  def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, state) do
    Logger.error "#{consumer_tag} : basic_cancel"
    {:stop, :normal, state}
  end

  def handle_info(
        {:basic_deliver, payload, %{delivery_tag: tag,
          redelivered: redelivered, consumer_tag: consumer_tag}},
        state
      ) do
    Logger.info "#{consumer_tag} : basic_deliver"
    consume(state[:channel], tag, redelivered, payload, state)
    {:noreply, state}
  end
end
