# SPDX-FileCopyrightText: 2021 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2023 Digit
# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule SHT4X.Measurement do
  @moduledoc """
  One sensor measurement
  """
  require Logger

  use TypedStruct

  # Raw readings that, when converted, equate to the min and max operating
  # ranges of Rh and temp [0 - 100] for Rh and [-40 - 125] for temperature.
  # Expand range by 1 to avoid ceiling/floor issues.
  @min_raw_rh 0x0C4A - 1
  @max_raw_rh 0xD915 + 1

  @min_raw_t 0x0750 - 1
  @max_raw_t 0xF8AE + 1

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
  def from_raw(<<raw_t::16, raw_rh::16>>) do
    timestamp_ms = System.monotonic_time(:millisecond)

    if raw_reading_valid?(raw_t, raw_rh) do
      make_measurement(raw_t, raw_rh, timestamp_ms)
    else
      # Raw readings invalid, don't even attempt to convert them
      Logger.warning("Your SHT4X is returning values that could indicate it is damaged!")

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
    temperature_c = raw_to_temperature_c(raw_t)
    humidity_rh = raw_to_humidity_rh(raw_rh)

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

  @spec raw_to_humidity_rh(0..0xFFFF) :: float()
  def raw_to_humidity_rh(raw_rh) do
    -6 + 125 * raw_rh / (0xFFFF - 1)
  end

  @spec humidity_rh_to_raw(float()) :: integer()
  def humidity_rh_to_raw(rh) do
    round((rh + 6) / 125 * (0xFFFF - 1))
  end

  @spec raw_to_temperature_c(0..0xFFFF) :: float()
  def raw_to_temperature_c(raw_t) do
    -45 + 175 * raw_t / (0xFFFF - 1)
  end

  @spec temperature_c_to_raw(float()) :: integer()
  def temperature_c_to_raw(t) do
    round((t + 45) / 175 * (0xFFFF - 1))
  end

  # Function to check the raw values read from the sensor
  # A few bad values are known: 0x8000 and 0x8001 (according to Sensirion)
  defp raw_reading_valid?(0x8000, 0x8000), do: false
  defp raw_reading_valid?(0x8001, 0x8000), do: false

  # Ensure raw values would be within min/max operating ranges
  defp raw_reading_valid?(t, _rh) when t not in @min_raw_t..@max_raw_t, do: false
  defp raw_reading_valid?(_t, rh) when rh not in @min_raw_rh..@max_raw_rh, do: false

  defp raw_reading_valid?(_t, _rh), do: true
end
