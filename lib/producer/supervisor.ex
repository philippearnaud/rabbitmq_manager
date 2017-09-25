defmodule RabbitsManager.Producer.Supervisor do
  @moduledoc false

  use Supervisor
  alias RabbitsManager.Config

  def start_link(_arg) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    workers = Config.create_producers_supervised_specs()
    Supervisor.init(workers, strategy: :one_for_one)
  end
end
