defmodule SHT4X do
  @moduledoc """
  Use Sensirion SHT4X humidity and temperature sensors in Elixir
  """

  use GenServer

  require Logger

  @typedoc """
  Compensation callback function
  """
  @type compensation_callback :: (SHT4X.Measurement.t() -> SHT4X.Measurement.t()) | nil

  @typedoc """
  SHT4X GenServer start_link options
  * `:name` - a name for the GenServer
  * `:bus_name` - which I2C bus to use (e.g., `"i2c-1"`)
  * `:retries` - the number of retries before failing (defaults to 3 retries)
  * `:compensation_callback` - a function that takes in a `SHT4X.Measurement.t()` and returns a potentially modified `SHT4X.Measurement.t()`
  * `:measurement_interval` - how often data will be read from the sensor (defaults to 5_000 ms)
  * `:repeatability` - accuracy of the requested sensor read (`:low`, `:medium`, or `:high`)
  * Also accepts all other standard `GenServer` start_link options
  """
  @type option ::
          {:debug, GenServer.debug()}
          | {:name, GenServer.name()}
          | {:timeout, timeout()}
          | {:spawn_opt, [Process.spawn_opt()]}
          | {:hibernate_after, timeout()}
          | {:bus_name, binary()}
          | {:retries, pos_integer()}
          | {:compensation_callback, compensation_callback()}
          | {:measurement_interval, pos_integer()}
          | {:repeatability, :low | :medium | :high}

  @type options :: [option()]

  @default_bus_name "i2c-1"
  @default_interval 5_000
  @default_retries 3
  @default_repeatability :high
  @default_func &Function.identity/1
  @bus_address 0x44

  ## Public API

  @doc """
  Start a new GenServer for interacting with a SHT4X.
  """
  @spec start_link(options()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    gen_server_opts = Keyword.take(opts, [:name, :debug, :timeout, :spawn_opt, :hibernate_after])

    init_arg =
      Keyword.take(opts, [
        :bus_name,
        :retries,
        :compensation_callback,
        :measurement_interval,
        :repeatability
      ])

    GenServer.start_link(__MODULE__, init_arg, gen_server_opts)
  end

  @doc """
  Returns the latest temperature and humidity measurement
  An error is returned if a measurement isn't available
  """
  @spec measure(GenServer.server()) :: {:ok, SHT4X.Measurement.t()} | {:error, :no_data}
  def measure(server) do
    GenServer.call(server, :measure)
  end

  ## Callbacks

  @impl GenServer
  def init(init_arg) do
    bus_name = init_arg[:bus_name] || @default_bus_name
    bus_address = @bus_address

    Logger.info(
      "[SHT4X] Starting on bus #{bus_name} at address #{inspect(bus_address, base: :hex)}"
    )

    options = [
      retries: Keyword.get(init_arg, :retries, @default_retries),
      compensation_callback: Keyword.get(init_arg, :compensation_callback, @default_func),
      measurement_interval: Keyword.get(init_arg, :measurement_interval, @default_interval),
      repeatability: Keyword.get(init_arg, :repeatability, @default_repeatability)
    ]

    with {:ok, transport} <- SHT4X.Transport.new(bus_name, bus_address, options[:retries]),
         {:ok, serial_number} <- SHT4X.Comm.serial_number(transport) do
      state = %{
        options: options,
        current_measurement: nil,
        last_raw_measurement: nil,
        serial_number: serial_number,
        transport: transport
      }

      interval = Keyword.get(init_arg, :measurement_interval, @default_interval)
      {:ok, _tref} = :timer.send_interval(interval, :do_measure)

      Logger.info(
        "[SHT4X] Initializing | S/N: #{serial_number} | Options: #{inspect(state.options)}"
      )

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
  def handle_info(:do_measure, state) do
    compensation_callback = state.options[:compensation_callback]

    case SHT4X.Comm.measure(state.transport, state.options) do
      {:ok, data} ->
        measurement_raw = SHT4X.Measurement.from_raw(data)
        measurement_compensated = compensation_callback.(measurement_raw)

        {:noreply,
         %{
           state
           | current_measurement: measurement_compensated,
             last_raw_measurement: measurement_raw
         }}

      _ ->
        # Always call the compensation function on the last good raw reading we had, if there is one.
        if state.last_raw_measurement == nil do
          {:noreply, state}
        else
          measurement_compensated = compensation_callback.(state.last_raw_measurement)
          {:noreply, %{state | current_measurement: measurement_compensated}}
        end
    end
  end

  @impl GenServer
  def handle_call(:measure, _from, state) do
    if state.current_measurement == nil do
      {:reply, {:error, :no_data}, state}
    else
      {:reply, {:ok, state.current_measurement}, state}
    end
  end
end
