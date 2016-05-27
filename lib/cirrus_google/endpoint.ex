defmodule Cirrus.Google.Endpoint do
  @moduledoc """
  Provides a authentication and request management
  mechanism that functions as a proxy between the
  HTTP client and the Service modules (Storage, Compute, etc).
  """

  defmacro __using__(_) do
    quote do
      alias Cirrus.{HTTP, Google.Config, Google.Token}

      @grant_type Application.get_env(
        :cirrus_google,
        :grant_type,
        "urn:ietf:params:oauth:grant-type:jwt-bearer"
      )
      @default_scope Application.get_env(
        :cirrus_google,
        :default_scope,
        "https://googleapis.com/auth/cloud-platform"
      )

      def fetch_token, do: fetch_token(@default_scope)
      def fetch_token(scope) do
        {:ok, client_email} = Config.get(:client_email)
        {:ok, token_uri} = Config.get(:token_uri)
        assertion = Token.claims(client_email, scope)
                    |> Token.encode
        headers = [
          {"Content-Type", "x-www-form-urlencoded"}
        ]

        form = {:form, [
          assertion: assertion,
          grant_type: @grant_type
        ]}

        case HTTP.request(:post, token_uri, headers, form) do
          {:ok, %HTTP.Response{body: body}} ->
            body = Poison.decode!(body)
            {:ok, %{token: body["access_token"], expires_in: body["expires_in"], type: "Bearer"}}
        end
      end

      def process_request_url(url) do
        case URI.parse(url) do
          %URI{host: nil} ->
            Application.get_env(:cirrus_google, :host) <> url
          _ -> url
        end
      end

      def process_request_headers(headers \\ []) do
        unless List.keyfind(headers, "Content-Type", 0) do
          [{"Content-Type",
            "application/json"} | headers]
        end

        unless List.keyfind(headers, "Authorization", 0) do
          {:ok, response} = fetch_token
          [{"Authorization",
            "#{response.type} #{response.token}"} | headers]
        end
      end

      def process_request_options(options \\ []) do
        unless Keyword.get(options, :query) do
          options = Keyword.put(options, :query, [])
        end

        unless Keyword.get(options[:query], :project) do
          {:ok, project_id} = Config.get(:project_id)
          update_in(
            options[:query],
            &Keyword.put(&1, :project, project_id)
          )
        end
      end

      def process_response(response) do
        response.body |> Poison.decode!
      end

      def request(method, url, headers \\ []),
        do: request(method, url, headers, "", [])
      def request(method, url, headers, body),
        do: request(method, url, headers, body, [])
      def request(method, url, headers, body, options) do
        url = url |> process_request_url
        headers = headers |> process_request_headers
        options = options |> process_request_options

        case HTTP.request(method, url, headers, body, options) do
          {:ok, response} ->
            {:ok, process_response(response)}
          {:error, error} ->
            {:error, error}
        end
      end
    end
  end
end
