defmodule SHT4X do
  @moduledoc """
  Use Sensirion SHT4X humidity and temperature sensors in Elixir
  """

  use GenServer

  require Logger

  @typedoc """
  SHT4X GenServer start_link options
  * `:name` - a name for the GenServer
  * `:bus_name` - which I2C bus to use (e.g., `"i2c-1"`)
  * `:retries` - the number of retries before failing (defaults to no retries)
  """
  @type options() :: [GenServer.option() | {:bus_name, binary}]

  @default_bus_name "i2c-1"
  @bus_address 0x44

  ## Public API

  @doc """
  Start a new GenServer for interacting with a SHT4X.
  """
  @spec start_link(options()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    gen_server_opts = Keyword.take(opts, [:name, :debug, :timeout, :spawn_opt, :hibernate_after])
    init_arg = Keyword.take(opts, [:bus_name, :retries])

    GenServer.start_link(__MODULE__, init_arg, gen_server_opts)
  end

  @doc """
  Measure the current temperature and pressure.
  An error is returned if the I2C transactions fail.
  """
  @spec measure(GenServer.server(), Keyword.t()) :: {:ok, SHT4X.Measurement.t()} | {:error, any}
  def measure(server, opts \\ []) do
    GenServer.call(server, {:measure, opts})
  end

  ## Callbacks

  @impl GenServer
  def init(init_arg) do
    bus_name = init_arg[:bus_name] || @default_bus_name
    bus_address = @bus_address
    retries = init_arg[:retries] || 0

    Logger.info(
      "[SHT4X] Starting on bus #{bus_name} at address #{inspect(bus_address, base: :hex)}"
    )

    with {:ok, transport} <- SHT4X.Transport.new(bus_name, bus_address, retries),
         {:ok, serial_number} <- SHT4X.Comm.serial_number(transport) do
      Logger.info("[SHT4X] Initializing sensor #{serial_number}")

      state = %{
        serial_number: serial_number,
        transport: transport
      }

      {:ok, state}
    else
      {:error, reason} ->
        Logger.error("[SHT4X] Error connecting to sensor: #{reason}")
        {:stop, :normal}

      :error ->
        Logger.error("[SHT4X] Error connecting to sensor")
        {:stop, :normal}
    end
  end

  @impl GenServer
  def handle_call({:measure, opts}, _from, state) do
    {:ok, data} = SHT4X.Comm.measure(state.transport, opts)
    {:reply, {:ok, SHT4X.Measurement.from_raw(data)}, state}
  end
end
