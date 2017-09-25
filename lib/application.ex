defmodule RabbitsManager.Application do
  @moduledoc false

  use Application

  alias RabbitsManager.Supervisor

  def start(_type, _args) do
    RabbitsManager.Supervisor.start_link()
  end
end