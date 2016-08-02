defmodule Couchex.Mixfile do
  use Mix.Project

  def project do
    [app: :couchex,
     version: "0.0.7",
     elixir: ">= 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :hackney, :poison],
     mod: {Couchex, []}]
  end

  # Dependencies can be Hex packages:
  #
  defp deps do
    [
      {:hackney, ">= 1.3.0"},
      {:honeydew, ">= 0.0.5"},
      {:poison, ">= 1.5.0"}
    ]
  end
end
