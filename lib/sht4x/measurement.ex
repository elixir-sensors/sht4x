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
    compensation_func = Keyword.get(opts, :compensation_func, &Function.identity/1)

    __struct__(
      humidity_rh: humidity_rh_from_raw(raw_rh),
      temperature_c: temperature_c_from_raw(raw_t),
      raw_reading_temperature: raw_t,
      raw_reading_humidity: raw_rh,
      timestamp_ms: System.monotonic_time(:millisecond)
    )
    |> compensation_func.()
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
