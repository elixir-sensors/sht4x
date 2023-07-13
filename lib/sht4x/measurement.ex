defmodule SHT4X.Measurement do
  @moduledoc """
  One sensor measurement
  """

  use TypedStruct

  typedstruct do
    field(:dew_point_c, number)
    field(:humidity_rh, number, enforce: true)
    field(:temperature_c, number, enforce: true)
    field(:raw_reading_temperature, integer, enforce: true)
    field(:raw_reading_humidity, integer, enforce: true)
    field(:timestamp_ms, integer, enforce: true)
    field(:quality, SHT4X.quality(), enforce: true)
  end

  @doc """
  Interprets one raw temperature/humidity message

  This returns a Measurement struct with the raw register values and their
  interpreted temperature and humidity.  It does not apply any compensation so
  this is real temperature and humidity detected.
  """
  @spec from_raw(<<_::48>>) :: t()
  def from_raw(<<raw_t::16, _crc1, raw_rh::16, _crc2>>) do
    timestamp_ms = System.monotonic_time(:millisecond)
    temperature_c = temperature_c_from_raw(raw_t)
    humidity_rh = humidity_rh_from_raw(raw_rh)

    __struct__(
      temperature_c: temperature_c,
      humidity_rh: humidity_rh,
      dew_point_c: SHT4X.Calc.dew_point(humidity_rh, temperature_c),
      raw_reading_temperature: raw_t,
      raw_reading_humidity: raw_rh,
      timestamp_ms: timestamp_ms,
      quality: :fresh
    )
  end

  defp humidity_rh_from_raw(raw_rh) do
    -6 + 125 * raw_rh / (0xFFFF - 1)
  end

  defp temperature_c_from_raw(raw_t) do
    -45 + 175 * raw_t / (0xFFFF - 1)
  end
end
