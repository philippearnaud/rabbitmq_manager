defmodule RabbitsManager.Supervisor do
  @moduledoc false

  use Supervisor

  alias RabbitsManager.{ConnectionManager}
  alias RabbitsManager.Consumer.Supervisor, as: ConsumerSupervisor
  alias RabbitsManager.Producer.Supervisor, as: ProducerSupervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Supervisor.init(
      [
        ConnectionManager,
        ConsumerSupervisor,
        ProducerSupervisor
      ],
      strategy: :one_for_one
    )
  end
end