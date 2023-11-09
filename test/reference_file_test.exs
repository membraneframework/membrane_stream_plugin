defmodule Membrane.Stream.ReferenceFileTest do
  use ExUnit.Case, async: true

  # Backwards compatibility is a core concept of this plugin
  # Therefore, updating the reference file to let the tests pass isn't acceptable
  # This strange looking test case is meant to discourage it

  test "v1 reference file wasn't changed" do
    assert {:ok, contents} = File.read("test/fixtures/v1.msr")

    # If you see this check modified by the Pull Request, refer to the comment above and request changes
    assert hash(contents) == "15bca6e6da1886b7bd14b4c6a8bf8c6078c5dfebd9e33e7eee35c01b6d4960a2",
           "Reference file must stay the same"
  end

  # This equivalent to running sha256sum command on Linux
  defp hash(data), do: :sha256 |> :crypto.hash(data) |> Base.encode16() |> String.downcase()
end
