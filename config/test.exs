use Mix.Config

config :app, App.Repo,
  pool: Ecto.Adapters.SQL.Sandbox
