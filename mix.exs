defmodule Lists.Mixfile do
  use Mix.Project

  def project do
    [
      app: :lists,
      version: "0.0.2",
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      mod: {Lists, []},
      applications: [:logger, :cowboy, :plug, :poison, :eex, :tzdata]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps() do
    [{:cowboy, "~> 2.5.0"}, {:plug, "~> 1.6.4"}, {:poison, "~> 4.0.1"}, {:timex, "~> 3.4.1"}]
  end
end
