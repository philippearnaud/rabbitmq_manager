defmodule RabbitsManager.Consumer.Supervisor do
  @moduledoc false

  use Supervisor

  alias RabbitsManager.{Consumer.Worker, Config}

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(arg) do
    workers = Config.create_consumers_supervised_specs()
    Supervisor.init(workers, strategy: :one_for_one)
  end
end