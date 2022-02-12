defmodule SHT4X do
  @moduledoc """
  Use Sensirion SHT4X humidity and temperature sensors in Elixir
  """

  use GenServer

  require Logger

  @type options() :: [GenServer.option() | {:bus_name, bus_name}]

  @typedoc """
  Which I2C bus to use (defaults to `"i2c-1"`)
  """
  @type bus_name :: binary

  @default_bus_name "i2c-1"
  @bus_address 0x44

  @spec start_link(options()) :: GenServer.on_start()
  def start_link(init_arg \\ []) do
    gen_server_opts =
      Keyword.take(init_arg, [:name, :debug, :timeout, :spawn_opt, :hibernate_after])

    GenServer.start_link(__MODULE__, init_arg, gen_server_opts)
  end

  @spec measure(GenServer.server(), Keyword.t()) :: {:ok, SHT4X.Measurement.t()} | {:error, any}
  def measure(server, opts \\ []) do
    GenServer.call(server, {:measure, opts})
  end

  @impl GenServer
  def init(init_arg) do
    bus_name = init_arg[:bus_name] || @default_bus_name
    bus_address = @bus_address

    Logger.info(
      "[SHT4X] Starting on bus #{bus_name} at address #{inspect(bus_address, base: :hex)}"
    )

    transport = SHT4X.Transport.new(bus_name, bus_address)

    case SHT4X.Comm.serial_number(transport) do
      {:ok, serial_number} ->
        Logger.info("[SHT4X] Initializing sensor #{serial_number}")

        state = %{
          serial_number: serial_number,
          transport: transport
        }

        {:ok, state}

      _error ->
        {:stop, "Error connecting to the sensor"}
    end
  end

  @impl GenServer
  def handle_call({:measure, opts}, _from, state) do
    {:ok, data} = SHT4X.Comm.measure(state.transport, opts)
    {:reply, {:ok, SHT4X.Measurement.from_raw(data)}, state}
  end
end
