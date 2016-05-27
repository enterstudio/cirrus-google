defmodule Cirrus.Google.Token do
  @moduledoc """
  Provides a basic mechanism for creating and encoding
  JWT Bearer Tokens, to be used with Google's OAuth2
  Service Account system.
  """
  alias Cirrus.HTTP
  alias Cirrus.Google.Config
  alias JOSE.{JWK, JWT, JWS}

  @jws %{"alg" => "RS256"}
  @aud "https://accounts.google.com/o/oauth2/token"

  def claims(iss, scope),
    do: claims(iss, scope, :os.system_time(:seconds))
  def claims(iss, scope, iat),
    do: claims(iss, scope, iat, iat + 10)
  def claims(iss, scope, iat, exp) when is_list(scope),
    do: claims(iss, Enum.join(scope, " "), iat, exp)
  def claims(iss, scope, iat, exp) do
    %{
      "aud" => @aud,
      "iss" => iss,
      "scope" => scope,
      "iat" => iat,
      "exp" => exp
    }
  end

  def encode(payload \\ %{}) do
    {:ok, key} = Config.get(:private_key)
    
    claims = JOSE.encode(payload)
    jwk = JWK.from_pem(key)

    JWT.sign(jwk, @jws, claims) |> JWS.compact |> elem(1)
  end
end
