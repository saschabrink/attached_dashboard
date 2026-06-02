import Config

config :tailwind,
  version: "4.1.12",
  attached_dashboard: [
    args: ~w(--input=assets/css/app.css --output=priv/static/css/app.css),
    cd: Path.expand("..", __DIR__)
  ]

config :esbuild,
  version: "0.25.4",
  attached_dashboard: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outfile=../priv/static/js/app.js),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]
