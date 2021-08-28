defmodule SHT4X.Calc do
  @moduledoc false

  use Bitwise

  @doc """
  The 8-bit CRC checksum transmitted after each data word. See Sensirion docs:
  * [Data sheet](https://cdn-learn.adafruit.com/assets/assets/000/097/511/original/Sensirion_Gas-Sensors_SGP40_Datasheet.pdf) - Section 4
  * https://github.com/Sensirion/embedded-common/blob/1ac7c72c895d230c6f1375865f3b7161ce6b665a/sensirion_common.c#L60

  ## Examples

      # list of bytes
      iex> checksum([0xBE, 0xEF])
      0x92
      iex> checksum([0x80, 0x00])
      0xA2
      iex> checksum([0x66, 0x66])
      0x93

      # binary
      iex> checksum(<<0xBEEF::16>>)
      0x92
      iex> checksum(<<0x8000::16>>)
      0xA2
      iex> checksum(<<0x6666::16>>)
      0x93

  """
  @spec checksum(binary | list) :: byte
  def checksum(bytes_binary) when is_binary(bytes_binary) do
    bytes_binary |> :binary.bin_to_list() |> checksum()
  end

  def checksum(bytes_list) when is_list(bytes_list) do
    Enum.reduce(bytes_list, 0xFF, &process_byte_for_checksum/2) &&& 0xFF
  end

  defp process_byte_for_checksum(byte, acc) do
    Enum.reduce(0..7, bxor(acc, byte), fn _bit, acc ->
      case acc &&& 0x80 do
        0 -> acc <<< 1
        _ -> bxor(acc <<< 1, 0x31)
      end
    end)
  end

  @doc """
  Calculates the dew point using the August–Roche–Magnus approximation. See
  https://en.wikipedia.org/wiki/Clausius%E2%80%93Clapeyron_relation#Meteorology_and_climatology
  """
  @spec dew_point(number(), number()) :: float()
  def dew_point(humidity_rh, temperature_c) when is_number(humidity_rh) and humidity_rh > 0 do
    log_rh = :math.log(humidity_rh / 100)
    t = temperature_c

    243.04 * (log_rh + 17.625 * t / (243.04 + t)) / (17.625 - log_rh - 17.625 * t / (243.04 + t))
  end
end
