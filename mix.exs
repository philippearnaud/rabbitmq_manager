defmodule RabbitsManager.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rabbitmq_manager,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      package: package(),
      description: description()
    ]
  end

  defp description() do
    "RabbitsManager aims to allow easy to complex rabbitMQ setup following
  RabbitsMQ best practices"
  end

  defp package() do
    [
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Philippe de MANGOU"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/philippearnaud/rabbitmq_manager"
      }
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {RabbitsManager.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:amqp_client, "~> 3.6"},
      {:amqp, "~> 0.3.0"}
    ]
  end
end
