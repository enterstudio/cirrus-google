defmodule Cirrus.GoogleTest do
  use ExUnit.Case
  doctest Cirrus.Google

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "go" do
    Cirrus.Google.Storage.list_buckets
  end
end
