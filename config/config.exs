import Config

env_file = "#{config_env()}.exs"
if File.exists?(Path.join(__DIR__, env_file)), do: import_config(env_file)
