defmodule SHT4X.Measurement do
  @moduledoc """
  One sensor measurement
  """

  defstruct [:humidity_rh, :temperature_c, :timestamp_ms]

  @type t :: %{
          required(:timestamp_ms) => non_neg_integer(),
          required(:humidity_rh) => number,
          required(:temperature_c) => number,
          optional(:__struct__) => atom
        }

  @spec from_raw(integer, integer) :: t()
  def from_raw(raw_t, raw_rh) do
    __struct__(
      humidity_rh: humidity_rh_from_raw(raw_rh),
      temperature_c: temperature_c_from_raw(raw_t),
      timestamp_ms: System.monotonic_time(:millisecond)
    )
  end

  defp humidity_rh_from_raw(raw_rh) do
    -6 + 125 * raw_rh / (0xFFFF - 1)
  end

  defp temperature_c_from_raw(raw_t) do
    -45 + 175 * raw_t / (0xFFFF - 1)
  end
end
