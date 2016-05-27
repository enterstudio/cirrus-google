defmodule Cirrus.Google.Storage do
  use Cirrus.Google.Endpoint,
    default_scope: "https://www.googleapis.com/auth/cloud-platform"

  def endpoint, do: "/storage/v1/b"
  def endpoint(id), do: "/storage/v1/b/#{id}"

  def list_buckets do
    buckets = request(:get, endpoint)
    IO.inspect(buckets)
  end
end
