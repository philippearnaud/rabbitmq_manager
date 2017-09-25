defmodule RabbitsManager.Producer.Supervisor do
  @moduledoc false

  use Supervisor

  alias RabbitsManager.Producer.Worker
  alias RabbitsManager.Config

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(arg) do
    workers = Config.create_producers_supervised_specs()
    Supervisor.init(workers, strategy: :one_for_one)
  end
end