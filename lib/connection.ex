defmodule RabbitsManager.ConnectionManager do
  @moduledoc """
  This GenServer allow us to handle connection with rabbitMQ.

  When we initialize the connection Manager, we check if there are
  no issues with the configuration. If so, an exception is raised and the app
  is shut down. If no issues are found, then the connection manager send a connect
  command in order to ask for a connection. If it works, then the connection is merged
  into the GenServer state.

  Producers and Workers can fetch the connection at any given time.
  """
  use GenServer, restart: :permanent
  use AMQP

  alias RabbitsManager.Config

  require Logger

  def start_link(_arg) do
    params = []
    GenServer.start_link(__MODULE__, params, name: :rmq_connection_manager)
  end

  ### 1. CONNECTION STUFF ###
  ### WE MUST NOT INITIALIZE CONNECTION IN INIT OF A SUPERVISED PROCESS
  ### CAUSE IT WILL IMPACT STABILITY OF THE SYSTEM.
  ### RESTARTING A PROCESS IS ABOUT BRINGING IT BACK TO A STABLE STATE.
  def init(auth_params) do
    Process.send(self(), :connect, [])
    {:ok, [auth: auth_params, connection: nil]}
  end

  defp connect do
    connection_params = Config.connection_params
    case Connection.open(connection_params)  do
      {:ok, connection} ->
        Logger.info "#{__MODULE__} : Connection established with rabbitMQ server"
        Process.monitor(connection.pid)
        {:ok, connection}

      {:error, _} ->
        Process.send_after(self(), :connect, 5_000)
        Logger.error "#{
          __MODULE__
        } : can't establish a connection with rabbitMQ server. Try reconnecting in 5 secondes."
        {:error, :not_connected}
    end
  end

  def get_connection do
    GenServer.call(:rmq_connection_manager, :get_connection)
  end

  defp get_connection(%AMQP.Connection{pid: pid}), do: {:ok, %AMQP.Connection{pid: pid}}
  defp get_connection(_), do: {:error, :not_connected}

  ##### 2. GenServer callbacks ####

  # Allow a process to fetch a connection.
  # If connection can never be reach, {:error, :not_connected}
  # will be returned.
  def handle_call(:get_connection, _from, state) do
    {:reply, get_connection(state[:connection]), state}
  end

  # If system down, then crash.
  def handle_info({:DOWN, _, :process, _pid, _reason}, state)  do
    {:stop, :normal, state}
  end

  # Allow connecting.
  def handle_info(:connect, state) do
    {_, connection} = connect
    {:noreply, Keyword.merge(state, [connection: connection])}
  end
end
