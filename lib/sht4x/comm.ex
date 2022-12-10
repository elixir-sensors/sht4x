defmodule SHT4X.Comm do
  @moduledoc false

  alias SHT4X.Transport

  @cmd_serial_number <<0x89>>
  @cmd_measure_high_repeatability <<0xFD>>
  @cmd_measure_medium_repeatability <<0xF6>>
  @cmd_measure_low_repeatability <<0xE0>>

  @spec serial_number(Transport.t()) :: {:ok, 0..0xFFFF_FFFF}
  def serial_number(transport) do
    with {:ok, <<data1::16, _crc1, data2::16, _crc2>>} <- read_data(transport, @cmd_serial_number) do
      <<value::unsigned-big-32>> = <<data1::16, data2::16>>
      {:ok, value}
    end
  end

  @spec measure(Transport.t(), Enum.t()) :: {:ok, <<_::48>>}
  def measure(transport, opts \\ []) do
    do_measure(transport, opts[:repeatability] || :high)
  end

  @spec do_measure(Transport.t(), :low | :medium | :high) :: {:ok, <<_::48>>}
  defp do_measure(transport, :low) do
    read_data(transport, @cmd_measure_low_repeatability, 1)
  end

  defp do_measure(transport, :medium) do
    read_data(transport, @cmd_measure_medium_repeatability, 4)
  end

  defp do_measure(transport, :high) do
    read_data(transport, @cmd_measure_high_repeatability, 8)
  end

  @spec read_data(Transport.t(), iodata, non_neg_integer()) :: {:ok, <<_::48>>}
  defp read_data(transport, command, delay_ms \\ 1) do
    with :ok <- transport.write_fn.(command),
         :ok <- Process.sleep(delay_ms) do
      transport.read_fn.(6)
    end
  end
end
