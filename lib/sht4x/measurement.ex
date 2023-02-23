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
  end

  @spec from_raw(<<_::48>>, Keyword.t()) :: t()
  def from_raw(<<raw_t::16, _crc1, raw_rh::16, _crc2>>, opts) do
    temperature_compensation_func =
      Keyword.get(opts, :temperature_compensation_func, fn v -> v end)

    humidity_compensation_func = Keyword.get(opts, :humidity_compensation_func, fn v -> v end)

    corrected_raw_t = temperature_compensation_func.(raw_t)
    corrected_raw_rh = humidity_compensation_func.(raw_rh)

    __struct__(
      humidity_rh: humidity_rh_from_raw(corrected_raw_rh),
      temperature_c: temperature_c_from_raw(corrected_raw_t),
      raw_reading_temperature: raw_t,
      raw_reading_humidity: raw_rh,
      timestamp_ms: System.monotonic_time(:millisecond)
    )
    |> put_dew_point_c()
  end

  defp humidity_rh_from_raw(raw_rh) do
    -6 + 125 * raw_rh / (0xFFFF - 1)
  end

  defp temperature_c_from_raw(raw_t) do
    -45 + 175 * raw_t / (0xFFFF - 1)
  end

  defp put_dew_point_c(measurement) do
    struct!(
      measurement,
      dew_point_c: SHT4X.Calc.dew_point(measurement.humidity_rh, measurement.temperature_c)
    )
  end
end
