defmodule SHT4X.Calc do
  @moduledoc false

  @crc_alg :cerlc.init(:crc8_sensirion)

  @doc """
  Check the CRC on the temperature/humidity report

  The 8-bit CRC checksum transmitted after each data word. See Sensirion docs:

  * [Datasheet](https://developer.sensirion.com/fileadmin/user_upload/customers/sensirion/Dokumente/2_Humidity_Sensors/Datasheets/Sensirion_Humidity_Sensors_SHT4x_Datasheet.pdf)
  * https://github.com/Sensirion/embedded-common/blob/1ac7c72c895d230c6f1375865f3b7161ce6b665a/sensirion_common.c#L60

  ## Examples

      iex> SHT4X.Calc.crc_ok?(<<0xBEEF::16, 0x92, 0x8000::16, 0xA2>>)
      true

      iex> SHT4X.Calc.crc_ok?(<<0xBEEF::16, 0x92, 0x8000::16, 0xA3>>)
      false
  """
  @spec crc_ok?(<<_::48>>) :: boolean()
  def crc_ok?(<<raw_t::binary-size(2), crc1, raw_rh::binary-size(2), crc2>>) do
    crc1 == crc(raw_t) and crc2 == crc(raw_rh)
  end

  defp crc(bytes) do
    :cerlc.calc_crc(bytes, @crc_alg)
  end

  @doc """
  Calculates the dew point using the August–Roche–Magnus approximation. See
  https://en.wikipedia.org/wiki/Clausius%E2%80%93Clapeyron_relation#Meteorology_and_climatology

  ## Examples

      iex> SHT4X.Calc.dew_point(50, 22.0) |> round()
      11
  """
  @spec dew_point(number(), number()) :: float()
  def dew_point(humidity_rh, temperature_c) when is_number(humidity_rh) and humidity_rh > 0 do
    log_rh = :math.log(humidity_rh / 100)
    t = temperature_c

    243.04 * (log_rh + 17.625 * t / (243.04 + t)) / (17.625 - log_rh - 17.625 * t / (243.04 + t))
  end
end
