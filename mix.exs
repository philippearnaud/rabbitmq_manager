defmodule RabbitsManager.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rabbits_manager,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
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
      {:amqp_client, git: "https://github.com/dsrosario/amqp_client.git", branch: "erlang_otp_19", override: true},
      {:amqp, "~> 0.1.4"}
    ]
  end
end
