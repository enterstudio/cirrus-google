use Mix.Config

config :cirrus_google, :json,
  "config/test-credentials.json" |> File.read!
config :goth, json: "config/test-credentials.json" |> File.read!
