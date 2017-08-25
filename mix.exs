defmodule Reditex.Mixfile do
  use Mix.Project

  def project do
    [app: :reditex,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger],
     mod: {Reditex.Application, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:timex, "~> 3.1.24"},
      {:mongodb, "~> 0.2.0"},          # Mongo client
      {:cowboy, "~> 1.1"},             # For mongo
      {:plug, "~> 1.3"},
      {:poolboy, ">= 0.0.0"},          # For Plug router
      {:telex, git: "git@github.com:rockneurotiko/telex.git", tag: "0.3.2-rc6"},
      {:poison, "~> 3.1.0", override: true},
      {:httpoison, "~> 0.11.1"}, # HTTP Client
      {:distillery, "~> 1.0", runtime: false},
      {:dialyxir, "~> 0.4", only: [:dev], runtime: false}
    ]
  end
end
