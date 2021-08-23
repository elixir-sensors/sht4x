defmodule SHT4X.CommTest do
  use ExUnit.Case, async: true

  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "serial_number" do
    SHT4X.MockTransport
    |> Mox.expect(:write, 1, fn _transport, <<0x89>> ->
      :ok
    end)
    |> Mox.expect(:read, 1, fn _transport, 6 ->
      {:ok, <<15, 186, 124, 249, 143, 14>>}
    end)

    assert {:ok, 263_911_823} = SHT4X.Comm.serial_number(fake_transport())
  end

  defp fake_transport do
    :c.pid(0, 0, 0)
  end
end
