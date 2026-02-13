defmodule Discuss.Esbuild do
  def init(config) do
    unless Application.get_env(:discuss, :esbuild_version) do
      IO.warn(
        "esbuild not found in config. Ensure \"esbuild\" is listed as a dependency in mix.exs"
      )

      Application.put_env(:discuss, :esbuild_version, "0.17.0")
    end

    config
  end

  def profile(name) do
    [
      args:
        ~w(priv/static/js/app.js --bundle --target=es2017 --outdir=priv/static/assets) ++
          if(name == :prod, do: ~w(--minify), else: []),
      cd: File.cwd!(),
      env: %{"NODE_PATH" => Path.join(File.cwd!(), "deps")}
    ]
  end
end
