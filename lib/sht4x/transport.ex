defmodule SHT4X.Transport do
  @moduledoc false

  use TypedStruct

  typedstruct do
    field(:address, 0..127, enforce: true)
    field(:ref, reference, enforce: true)
    field(:retries, non_neg_integer, default: 0)
    field(:read_fn, (pos_integer -> {:ok, binary} | {:error, any}), enforce: true)
    field(:write_fn, (iodata -> :ok | {:error, any}), enforce: true)
    field(:write_read_fn, (iodata, pos_integer -> {:ok, binary} | {:error, any}), enforce: true)
  end

  @spec new(reference, 0..127, non_neg_integer) :: {:ok, t()} | {:error, any}
  def new(ref, address, retries)
      when is_reference(ref) and is_integer(address) and is_integer(retries) do
    opts = [retries: retries]

    {:ok,
     %__MODULE__{
       ref: ref,
       address: address,
       retries: retries,
       read_fn: &Circuits.I2C.read(ref, address, &1, opts),
       write_fn: &Circuits.I2C.write(ref, address, &1, opts),
       write_read_fn: &Circuits.I2C.write_read(ref, address, &1, &2, opts)
     }}
  end

  @spec new(binary, 0..127, non_neg_integer) :: {:ok, t()} | {:error, any}
  def new(bus_name, address, retries)
      when is_binary(bus_name) and is_integer(address) and is_integer(retries) do
    case Circuits.I2C.open(bus_name) do
      {:error, err} ->
        {:error, err}

      {:ok, ref} ->
        new(ref, address, retries)
    end
  end
end
