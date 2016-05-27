defmodule Cirrus.HTTP do
  @moduledoc """
  A simple HTTP client, tailored to the needs at hand.
  Based on HTTPoison/Hackney.
  """

  @type headers :: [{:binary, binary}]

  defmodule Response do
    defstruct status_code: nil, headers: [], body: nil
    @type t :: %Response{
      status_code: integer,
      body: binary,
      headers: Cirrus.HTTP.headers
    }
  end

  defmodule Error do
    defexception id: nil, reason: nil
    @type t :: %Error{id: reference, reason: any}

    def reason(%Error{reason: reason, id: nil}),
      do: inspect(reason)
    def message(%Error{reason: reason, id: id}),
      do: "[Reference: #{id}] - #{inspect(reason)}"
  end

  import URI, only: [parse: 1, encode_query: 1]

  @content_types %{
    json: "application/json",
    form: "application/x-www-form-urlencoded"
  }
  
  def request(method, url, headers, body, options \\ []) do
    if Keyword.has_key?(options, :query) do
      url = url <> "?" <> encode_query(
        Keyword.get(options, :query)
      )
    end

    case :hackney.request(method, url, headers, body, options) do
      {:ok, status_code, headers, client} ->
        process_response_body(client, status_code, headers)
      {:error, reason} ->
        process_error(reason)
    end
  end
  
  defp process_response_body(client, status_code, headers) do
    case :hackney.body(client) do
      {:ok, body} ->
        {:ok, %Response{
          body: body,
          status_code: status_code,
          headers: headers
        }}
      {:error, reason} ->
        {:error, %Error{
          reason: reason
        }}
    end
  end

  defp process_error(reason) do
    {:error, %Error{reason: reason}}
  end
end
