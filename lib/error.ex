defmodule RabbitsManager.ConsumerConfigError do
  alias __MODULE__, as: Error
  defexception [:message]

  @spec exception(tuple()) :: String.t
  def exception(error) do
    msg = "Key :#{elem(error, 0)} in consumer field must be set, got : #{elem(error, 1)}"
    %Error{message: msg}
  end
end

defmodule RabbitsManager.ProducerConfigError do
  alias __MODULE__, as: Error
  defexception [:message]

  @spec exception(tuple()) :: String.t
  def exception(error) do
    msg = "Key :#{elem(error, 0)} in producer must be set, got : #{elem(error, 1)}"
    %Error{message: msg}
  end
end

defmodule RabbitsManager.StandardConfigError do
  alias __MODULE__, as: Error
  defexception [:message]

  @spec exception(String.t) :: String.t
  def exception(_value) do
    msg = "You must declare a producer and/or a producer key(s) to start RabbitManager, got : none"
    %Error{message: msg}
  end
end
