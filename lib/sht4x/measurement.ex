defmodule SHT4X.Measurement do
  @moduledoc """
  One sensor measurement
  """
  require Logger

  use TypedStruct

  # Raw readings that, when converted, equate to the min and max operating ranges of Rh and temp
  # [0 - 100] for Rh and [-40 - 125] for temp
  @min_range_rh 0x0C4A
  @max_range_rh 0xD914

  @min_range_t 0x0751
  @max_range_t 0xF8AD

  typedstruct do
    field(:dew_point_c, float)
    field(:humidity_rh, float, enforce: true)
    field(:temperature_c, float, enforce: true)
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
  def from_raw(<<raw_t::16, _crc1, raw_rh::16, _crc2>>) do
    timestamp_ms = System.monotonic_time(:millisecond)

    if raw_reading_valid?(raw_t, raw_rh) do
      make_measurement(raw_t, raw_rh, timestamp_ms)
    else
      # Raw readings invalid, don't even attempt to convert them
      Logger.warning("Your sensor is returning values that could indicate it is damaged!")

      __struct__(
        temperature_c: 0.0,
        humidity_rh: 0.0,
        dew_point_c: 0.0,
        raw_reading_temperature: raw_t,
        raw_reading_humidity: raw_rh,
        timestamp_ms: timestamp_ms,
        quality: :unusable
      )
    end
  end

  defp make_measurement(raw_t, raw_rh, timestamp_ms) do
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

  # Function to check the raw values read from the sensor
  # A few bad values are known: 0x8000 and 0x8001 (according to Sensirion)
  defp raw_reading_valid?(0x8000, 0x8000), do: false
  defp raw_reading_valid?(0x8001, 0x8000), do: false

  # Ensure raw values would be within min/max operating ranges
  defp raw_reading_valid?(raw_t, raw_rh)
       when raw_rh not in @min_range_rh..@max_range_rh or raw_t not in @min_range_t..@max_range_t,
       do: false

  defp raw_reading_valid?(_raw_t, _raw_rh), do: true
end
