defmodule Discuss.Tailwind do
  def init(config) do
    unless Application.get_env(:discuss, :tailwind_version) do
      IO.warn(
        "tailwind not found in config. Ensure \"tailwind\" is listed as a dependency in mix.exs"
      )

      Application.put_env(:discuss, :tailwind_version, "3.4.0")
    end

    config
  end

  def profile(name) do
    [
      args: ~w(--input=priv/static/css/app.css --output=priv/static/assets/app.css) ++
        if(name == :prod, do: ~w(--minify), else: []),
      cd: File.cwd!()
    ]
  end
end
