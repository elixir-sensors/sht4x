defmodule SHT4X.Comm do
  @moduledoc false

  alias SHT4X.Transport.I2C

  use Bitwise

  @cmd_serial_number <<0x89>>
  @cmd_measure_high_repeatability <<0xFD>>
  @cmd_measure_medium_repeatability <<0xF6>>
  @cmd_measure_low_repeatability <<0xE0>>

  def serial_number(transport) do
    with {:ok, {data1, data2}} <- write_read_with_delay(transport, @cmd_serial_number) do
      <<value::unsigned-big-32>> = <<data1::16, data2::16>>
      {:ok, value}
    end
  end

  def measure(transport, opts \\ []) do
    repeatability = opts[:repeatability] || :high

    result =
      case repeatability do
        :low -> write_read_with_delay(transport, @cmd_measure_low_repeatability, 1)
        :medium -> write_read_with_delay(transport, @cmd_measure_medium_repeatability, 4)
        :high -> write_read_with_delay(transport, @cmd_measure_high_repeatability, 8)
      end

    case result do
      {:ok, {raw_t, raw_rh}} -> {:ok, SHT4X.Measurement.from_raw(raw_t, raw_rh)}
      error -> error
    end
  end

  def write_read_with_delay(transport, command, delay_ms \\ 1) do
    with :ok <- I2C.write(transport, command),
         :ok <- Process.sleep(delay_ms),
         {:ok, <<data1::16, _crc1, data2::16, _crc2>>} <- I2C.read(transport, 6) do
      {:ok, {data1, data2}}
    end
  end
end
