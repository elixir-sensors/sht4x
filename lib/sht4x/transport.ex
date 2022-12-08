defmodule SHT4X.Transport do
  @moduledoc false

  use TypedStruct

  typedstruct do
    field(:address, 0..127, enforce: true)
    field(:read_fn, (pos_integer, Keyword.t() -> {:ok, binary} | {:error, any}), enforce: true)
    field(:ref, reference, enforce: true)
    field(:write_fn, (iodata, Keyword.t() -> :ok | {:error, any}), enforce: true)
    field(:write_read_fn, (iodata, pos_integer -> {:ok, binary} | {:error, any}), enforce: true)
    field(:num_retries, pos_integer(), enforce: true)
  end

  @spec new(reference, 0..127, pos_integer()) :: SHT4X.Transport.t()
  def new(ref, address, retries) when is_reference(ref) and is_integer(address) and is_integer(retries) do
    %__MODULE__{
      ref: ref,
      address: address,
      read_fn: &Circuits.I2C.read(ref, address, &1, &2),
      write_fn: &Circuits.I2C.write(ref, address, &1, &2),
      write_read_fn: &Circuits.I2C.write_read(ref, address, &1, &2),
      num_retries: retries
    }
  end

  @spec new(binary, 0..127, pos_integer()) :: SHT4X.Transport.t()
  def new(bus_name, address, retries) when is_binary(bus_name) and is_integer(address) and is_integer(retries) do
    ref = open_i2c!(bus_name)
    new(ref, address, retries)
  end

  @spec open_i2c!(binary) :: reference
  defp open_i2c!(bus_name) do
    {:ok, ref} = Circuits.I2C.open(bus_name)
    ref
  end
end
