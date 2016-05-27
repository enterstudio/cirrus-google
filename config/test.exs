use Mix.Config

config :cirrus_google,
  :json, "config/test-credentials.json" |> File.read!
