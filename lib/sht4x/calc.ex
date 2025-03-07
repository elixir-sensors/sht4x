# SPDX-FileCopyrightText: 2021 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2023 Digit
# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule SHT4X.Calc do
  @moduledoc false

  @crc_alg :cerlc.init(:crc8_sensirion)

  @doc """
  Check CRCs and extract the payload from SHT4X responses

  The 8-bit CRC checksum transmitted after each data word. See Sensirion docs:

  * [Datasheet](https://developer.sensirion.com/fileadmin/user_upload/customers/sensirion/Dokumente/2_Humidity_Sensors/Datasheets/Sensirion_Humidity_Sensors_SHT4x_Datasheet.pdf)
  * https://github.com/Sensirion/embedded-common/blob/1ac7c72c895d230c6f1375865f3b7161ce6b665a/sensirion_common.c#L60

  ## Examples

      iex> SHT4X.Calc.extract_payload(<<0xBEEF::16, 0x92, 0x8000::16, 0xA2>>)
      {:ok, <<0xBEEF8000::32>>}

      iex> SHT4X.Calc.extract_payload(<<0xBEEF::16, 0x92, 0x8000::16, 0xA3>>)
      {:error, :crc_mismatch}
  """
  @spec extract_payload(<<_::48>>) :: {:ok, <<_::32>>} | {:error, :crc_mismatch}
  def extract_payload(<<val1::2-bytes, crc1, val2::2-bytes, crc2>>) do
    if crc1 == crc(val1) and crc2 == crc(val2) do
      {:ok, <<val1::2-bytes, val2::2-bytes>>}
    else
      {:error, :crc_mismatch}
    end
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
  @spec dew_point(float(), float()) :: float()
  def dew_point(humidity_rh, temperature_c) when is_number(humidity_rh) and humidity_rh > 0 do
    log_rh = :math.log(humidity_rh / 100)
    t = temperature_c

    243.04 * (log_rh + 17.625 * t / (243.04 + t)) / (17.625 - log_rh - 17.625 * t / (243.04 + t))
  end
end
