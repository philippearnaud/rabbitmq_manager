defmodule RabbitsManager.Producer.Worker do
  @moduledoc """
  Producer Worker.

  A producer worker is started with a producer_pattern as arguments wich is all
  informations defined in config file for the given consumers.
  """
  require Logger
  use GenServer
  use AMQP

  alias RabbitsManager.{ConnectionManager, Config}
  alias RabbitsManager.Producer.Messages

  def start_link(producer_pattern) do
    GenServer.start_link(__MODULE__, producer_pattern, name: producer_pattern[:key])
  end

  ### 1. CONNECTION STUFF ###
  ### WE MUST NOT INITIALIZE CONNECTION IN INIT OF A SUPERVISED PROCESS
  ### CAUSE IT WILL IMPACT STABILITY OF THE SYSTEM.
  ### RESTARTING A PROCESS IS ABOUT BRINGINT IT BACK TO A STABLE STATE.
  def init(state) do
    Process.send(self(), :init_producer, [])
    {:ok, state}
  end

  ##### 2. GenServer callbacks ####
  def handle_info(:init_producer, state) do
    new_state = init_producer(state)
    {:noreply, new_state}
  end
  # If system down, then crash.
  def handle_info({:DOWN, _, :process, _pid, _reason}, state)  do
    {:stop, :normal, state}
  end

  def handle_call(:is_confirm_mode?, _from, state) do
    {:reply, Keyword.get(state, :confirm_mode, false), state}
  end
  def handle_cast({:msg, payload, routing_key}, state) do
    key_rounting = if routing_key == "", do: state[:routing_key], else: routing_key
    Basic.publish(
      state[:channel],
      elem(state[:exchange], 0),
      key_rounting,
      payload,
      state[:publish_options]
    )
    {:noreply, state}
  end

  def handle_call({:msg, payload, routing_key}, _from, state) do
    key_rounting = if routing_key == "", do: state[:routing_key], else: routing_key
    Basic.publish(
      state[:channel],
      elem(state[:exchange], 0),
      key_rounting,
      payload,
      state[:publish_options]
    )
    reply = Confirm.wait_for_confirms(
      state[:channel],
      Keyword.get(state, :confirm_timeout, 5_000)
    )
    {:reply, reply, state}
  end

  @spec init_producer(list()) :: list()
  def init_producer(state) do
    # We link the connection process to the worker one to be notified when down.
    :rmq_connection_manager
    |> GenServer.whereis()
    |> Process.monitor()

    connection_result = ConnectionManager.get_connection()
    new_state = case connection_result do
      {:ok, connection} ->
        {:ok, channel} = setup_producer_config(state, connection)
        Logger.info "#{__MODULE__} : Channel established with RabbitMQ server"
        Keyword.merge(state, [connection: connection, channel: channel])
      {:error, :not_connected} ->
        Logger.warn "#{__MODULE__} : Channel could not be established. Waiting for connection."
        Process.send_after(self(), :init_producer, 10_000)
        state
    end
  end

  @spec setup_producer_config(list(), %Connection{}) :: {:ok, %Channel{}}
  def setup_producer_config(state, connection) do
    {:ok, channel} = Channel.open(connection)
    if Keyword.get(state, :confirm_mode, false) do
      Confirm.select(channel)
    end
    Config.declare_queue_and_exchanges(:producer, channel, state)
    {:ok, channel}
  end

  def publish_msg(key, payload, routing_key \\ "") do
    case GenServer.call(key, :is_confirm_mode?) do
      true ->
        GenServer.call(key, {:msg, payload, routing_key})
      false ->
        GenServer.cast(key, {:msg, payload, routing_key})
    end
  end
end
