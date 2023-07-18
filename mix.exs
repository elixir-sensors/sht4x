defmodule SHT4X.MixProject do
  use Mix.Project

  @version "0.2.3"
  @source_url "https://github.com/elixir-sensors/sht4x"
  @sht4x_datasheet_url "https://developer.sensirion.com/fileadmin/user_upload/customers/sensirion/Dokumente/2_Humidity_Sensors/Datasheets/Sensirion_Humidity_Sensors_SHT4x_Datasheet.pdf"

  def project do
    [
      app: :sht4x,
      version: @version,
      description: description(),
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      aliases: [],
      dialyzer: dialyzer(),
      docs: docs(),
      preferred_cli_env: %{
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs,
        credo: :lint,
        dialyzer: :lint
      }
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def description do
    "Use Sensirion SHT4X humidity and temperature sensors in Elixir"
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:circuits_i2c, "~> 2.0 or ~> 1.0"},
      {:credo, "~> 1.6", only: :lint, runtime: false},
      {:credo_binary_patterns, "~> 0.2.2", only: :lint, runtime: false},
      {:dialyxir, "~> 1.1", only: :lint, runtime: false},
      {:circuits_sim, "~> 0.1.0", only: [:dev, :test]},
      {:ex_doc, "~> 0.28", only: :docs, runtime: false},
      {:cerlc, "~> 0.2.0"},
      {:typed_struct, "~> 0.3.0"}
    ]
  end

  defp dialyzer() do
    [
      flags: [:missing_return, :extra_return, :unmatched_returns, :error_handling, :underspecs]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp package do
    %{
      files: [
        "lib",
        "test",
        "mix.exs",
        "README.md",
        "LICENSE",
        "CHANGELOG.md"
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Datasheet" => @sht4x_datasheet_url
      }
    }
  end
end
