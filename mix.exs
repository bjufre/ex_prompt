defmodule ExPrompt.MixProject do
  use Mix.Project

  @version "0.1.1"

  def project do
    [
      app: :ex_prompt,
      version: @version,
      elixir: "~> 1.5.3",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/ex_prompt",
      main: "ExPrompt",
      source_url: "https://github.com/behind-design/ex_prompt",
      extras: ["README.md"]
    ]
  end

  defp description do
    """
    ExPrompt is a helper package to add interactivity to your command line applications as easy as possible.
    """
  end

  defp package do
    [
     name: :ex_prompt,
     files: ["lib", "mix.exs", "README*", "LICENSE*"],
     maintainers: ["Bernat Jufré Martínez"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/behind-design/ex_prompt"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
     # Docs
     {:ex_doc, "~> 0.16", only: :dev, runtime: false},
     {:earmark, ">= 1.2.3", only: :dev, runtime: false},
    ]
  end
end
