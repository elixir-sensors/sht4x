defmodule SHT4X do
  @moduledoc """
  Use Sensirion SHT4X humidity and temperature sensors in Elixir
  """

  use GenServer

  require Logger

  @typedoc """
  Compensation callback function
  """
  @type compensation_callback :: (SHT4X.Measurement.t() -> SHT4X.Measurement.t())

  @typedoc """
  How "fresh" is the sample we fetched from the sensor's GenServer?

  In the event that the sensor fails to report back a measurement during a polling interval, we re-use the last sample.
  If this continues to happen over a time period that exceeds the `:stale_threshold`, we mark the re-used "current" sample as stale.

  The possible values can be:
  - `:fresh` - This is a recent sample. See the `:stale_threshold`.
  - `:stale` - This is an old sample that should be used with caution.
  - `:unusable` - This is a default sample when no measurements are available, or, the sensor is giving know bad values (see: https://github.com/elixir-sensors/sht4x/issues/29)
  - `:converging` - This is optionally set by the temperature compensation algorithm to indicate that it was recently restarted without historic state information and needs more time to give accurate values
  """
  @type quality :: :fresh | :stale | :unusable | :converging

  @typedoc """
  SHT4X GenServer start_link options

  * `:name` - a name for the GenServer
  * `:bus_name` - which I2C bus to use (e.g., `"i2c-1"`)
  * `:retries` - the number of retries before failing (defaults to 3 retries)
  * `:compensation_callback` - a function that takes in a `SHT4X.Measurement.t()` and returns a potentially modified `SHT4X.Measurement.t()`
  * `:measurement_interval` - how often data will be read from the sensor (defaults to 5_000 ms)
  * `:repeatability` - accuracy of the requested sensor read (`:low`, `:medium`, or `:high`)
  * `:stale_threshold` - number of milliseconds a sample can remain the current sample before it is marked stale
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
          | {:stale_threshold, pos_integer()}

  @type options :: [option()]

  @default_bus_name "i2c-1"
  @default_interval 5_000
  @default_retries 3
  @default_repeatability :high
  @default_func &Function.identity/1
  @bus_address 0x44

  # This is a hard-coded value to be retuning in the very unlikely situation that we have no reading at all
  # It's unusable, and marked as such in the `:quality` field.
  @hardcoded_value %SHT4X.Measurement{
    timestamp_ms: 0,
    raw_reading_humidity: 0,
    raw_reading_temperature: 0,
    temperature_c: 23.0,
    humidity_rh: 50.0,
    dew_point_c: 12.02,
    quality: :unusable
  }

  # Default number of milliseconds a sample has to remain the "current" sample before we consider it stale
  @default_stale_threshold 60_000

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
        :repeatability,
        :stale_threshold
      ])

    GenServer.start_link(__MODULE__, init_arg, gen_server_opts)
  end

  @doc """
  Fetches the latest sample from the sensor's GenServer

  This does not cause an on-demand read from the sensor. Check the `:quality`
  field for a quick assessment of how much to trust the measurement.
  """
  @spec get_sample(GenServer.server()) :: SHT4X.Measurement.t()
  def get_sample(sensor_ref) do
    GenServer.call(sensor_ref, :get_sample)
  end

  @doc """
  Return the sensor's serial number
  """
  @spec serial_number(GenServer.server()) :: {:ok, 0..0xFFFF_FFFF} | {:error, any()}
  def serial_number(sensor_ref) do
    GenServer.call(sensor_ref, :serial_number)
  end

  @doc """
  Send a soft reset command to the sensor
  """
  @spec soft_reset(GenServer.server()) :: :ok | {:error, any()}
  def soft_reset(sensor_ref) do
    GenServer.call(sensor_ref, :soft_reset)
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
      repeatability: Keyword.get(init_arg, :repeatability, @default_repeatability),
      stale_threshold: Keyword.get(init_arg, :repeatability, @default_stale_threshold)
    ]

    case SHT4X.Transport.new(bus_name, bus_address, options[:retries]) do
      {:ok, transport} ->
        state = %{
          options: options,
          current_measurement: @hardcoded_value,
          current_raw_measurement: @hardcoded_value,
          transport: transport
        }

        # Request an initial sample and schedule the following ones.
        send(self(), :do_sample)
        interval = Keyword.get(init_arg, :measurement_interval, @default_interval)
        {:ok, _tref} = :timer.send_interval(interval, :do_sample)

        Logger.info("[SHT4X] Initialized | Options: #{inspect(state.options)}")
        {:ok, state}

      {:error, reason} ->
        Logger.error("[SHT4X] Error connecting to sensor: #{inspect(reason)}")
        {:stop, :normal}
    end
  end

  @impl GenServer
  def handle_info(:do_sample, state) do
    compensation_callback = state.options[:compensation_callback]

    case SHT4X.Comm.measure(state.transport, state.options) do
      {:ok, data} ->
        measurement_raw = SHT4X.Measurement.from_raw(data)
        measurement_compensated = compensation_callback.(measurement_raw)

        {:noreply,
         %{
           state
           | current_measurement: measurement_compensated,
             current_raw_measurement: measurement_raw
         }}

      _error ->
        # Always call the compensation function on the last good raw reading we had, if there is one.
        # Unless the quality of that sample is unusable.
        if state.current_raw_measurement.quality == :unusable do
          {:noreply, state}
        else
          measurement_compensated = compensation_callback.(state.current_raw_measurement)
          check_staleness(state, measurement_compensated)
        end
    end
  end

  defp check_staleness(state, measurement_compensated) do
    now = System.monotonic_time(:millisecond)

    if now - measurement_compensated.timestamp_ms >= state.options[:stale_threshold] do
      # Mark the current samples as stale
      {:noreply,
       %{
         state
         | current_measurement: %{measurement_compensated | quality: :stale},
           current_raw_measurement: %{state.current_raw_measurement | quality: :stale}
       }}
    else
      {:noreply, %{state | current_measurement: measurement_compensated}}
    end
  end

  @impl GenServer
  def handle_call(:get_sample, _from, state) do
    {:reply, state.current_measurement, state}
  end

  def handle_call(:serial_number, _from, state) do
    {:reply, SHT4X.Comm.serial_number(state.transport), state}
  end

  def handle_call(:soft_reset, _from, state) do
    {:reply, SHT4X.Comm.soft_reset(state.transport), state}
  end
end
