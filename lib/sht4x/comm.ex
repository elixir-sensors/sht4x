defmodule SHT4X.Comm do
  @moduledoc false

  alias SHT4X.Calc
  alias SHT4X.Transport

  @cmd_serial_number <<0x89>>
  @cmd_measure_high_repeatability <<0xFD>>
  @cmd_measure_medium_repeatability <<0xF6>>
  @cmd_measure_low_repeatability <<0xE0>>
  @cmd_soft_reset <<0x94>>

  @spec serial_number(Transport.t()) :: {:ok, 0..0xFFFF_FFFF} | {:error, any()}
  def serial_number(transport) do
    with {:ok, <<serial::32>>} <- read_data(transport, @cmd_serial_number) do
      {:ok, serial}
    end
  end

  @spec soft_reset(Transport.t()) :: :ok | {:error, any()}
  def soft_reset(transport) do
    transport.write_fn.(@cmd_soft_reset)
  end

  @spec measure(Transport.t(), keyword) :: {:ok, <<_::32>>} | {:error, any()}
  def measure(transport, opts) do
    repeatability = opts[:repeatability]
    read_data(transport, cmd_measure(repeatability), delay_ms_for_measure(repeatability))
  end

  defp cmd_measure(:low), do: @cmd_measure_low_repeatability
  defp cmd_measure(:medium), do: @cmd_measure_medium_repeatability
  defp cmd_measure(:high), do: @cmd_measure_high_repeatability

  defp delay_ms_for_measure(:low), do: 1
  defp delay_ms_for_measure(:medium), do: 4
  defp delay_ms_for_measure(:high), do: 8

  @spec read_data(Transport.t(), iodata, non_neg_integer()) :: {:ok, <<_::32>>} | {:error, any}
  defp read_data(transport, command, delay_ms \\ 1) do
    with :ok <- transport.write_fn.(command),
         Process.sleep(delay_ms),
         {:ok, binary} <- transport.read_fn.(6) do
      Calc.extract_payload(binary)
    end
  end
end
