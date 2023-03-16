defmodule SHT4X.Comm do
  @moduledoc false

  alias SHT4X.Calc
  alias SHT4X.Transport

  @cmd_serial_number <<0x89>>
  @cmd_measure_high_repeatability <<0xFD>>
  @cmd_measure_medium_repeatability <<0xF6>>
  @cmd_measure_low_repeatability <<0xE0>>

  @spec serial_number(Transport.t()) :: {:ok, 0..0xFFFF_FFFF} | :error
  def serial_number(transport) do
    case read_data(transport, @cmd_serial_number) do
      {:ok, <<data1::16, _crc1, data2::16, _crc2>>} ->
        <<value::unsigned-big-32>> = <<data1::16, data2::16>>
        {:ok, value}

      _ ->
        :error
    end
  end

  @spec measure(Transport.t(), keyword) :: {:ok, <<_::48>>} | :error
  def measure(transport, opts) do
    repeatability = opts[:repeatability]
    do_measure(transport, repeatability)
  end

  @spec do_measure(Transport.t(), :low | :medium | :high) :: {:ok, <<_::48>>} | :error
  defp do_measure(transport, repeatability) do
    read_data(transport, cmd_measure(repeatability), delay_ms_for_measure(repeatability))
  end

  defp cmd_measure(:low), do: @cmd_measure_low_repeatability
  defp cmd_measure(:medium), do: @cmd_measure_medium_repeatability
  defp cmd_measure(:high), do: @cmd_measure_high_repeatability

  defp delay_ms_for_measure(:low), do: 1
  defp delay_ms_for_measure(:medium), do: 4
  defp delay_ms_for_measure(:high), do: 8

  defp check_crc(<<raw_t1, raw_t2, crc1, raw_rh1, raw_rh2, crc2>> = binary) do
    computed_crc1 = Calc.checksum(<<raw_t1, raw_t2>>)
    computed_crc2 = Calc.checksum(<<raw_rh1, raw_rh2>>)

    if computed_crc1 == crc1 && computed_crc2 == crc2 do
      {:ok, binary}
    else
      :error
    end
  end

  @spec read_data(Transport.t(), iodata, non_neg_integer()) :: {:ok, <<_::48>>} | :error
  defp read_data(transport, command, delay_ms \\ 1) do
    with :ok <- transport.write_fn.(command),
         :ok <- Process.sleep(delay_ms),
         {:ok, binary} <- transport.read_fn.(6),
         {:ok, binary} <- check_crc(binary) do
      {:ok, binary}
    else
      _ -> :error
    end
  end
end
