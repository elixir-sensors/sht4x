defmodule SHT4X.Transport do
  @moduledoc false

  use TypedStruct

  typedstruct do
    field(:address, Circuits.I2C.address(), enforce: true)
    # We want to allow ref to be of any type so that we can use sim etc as needed.
    field(:ref, any, enforce: true)
    field(:read_fn, (pos_integer -> {:ok, binary} | {:error, any}), enforce: true)
    field(:write_fn, (iodata -> :ok | {:error, any}), enforce: true)
    field(:retries, non_neg_integer, default: 0)
  end

  @spec new(String.t(), Circuits.I2C.address(), non_neg_integer) :: {:ok, t()} | {:error, any}
  def new(bus_name, address, retries)
      when is_binary(bus_name) and is_integer(address) and is_integer(retries) do
    with {:ok, ref} <- Circuits.I2C.open(bus_name) do
      {:ok,
       %__MODULE__{
         ref: ref,
         address: address,
         read_fn: &Circuits.I2C.read(ref, address, &1),
         write_fn: &Circuits.I2C.write(ref, address, &1),
         retries: retries
       }}
    end
  end
end
