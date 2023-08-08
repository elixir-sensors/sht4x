defmodule ExampleCompensation do
  @moduledoc """
  Example NIF to run temperature/humidity compensation
  """

  @typedoc """
  The internal compensation state is kept as a list of floats.
  """
  @type state() :: [float()]

  @doc """
  Pass this function to `SHT4X.start_link` using the `:compensation_callback` option

  SHT4X automatically polls the sensor at a default rate of once every 5
  seconds. This is a common default, but if that's not the default for the
  compensation algorithm you receive, you'll need to change that option too.

  This function internally calls the NIF compensate function, defined in the C
  source code.
  """
  @spec compensate(SHT4X.Measurement.t()) :: SHT4X.Measurement.t()
  def compensate(raw_measurement) do
    # Get measurements from other places that impact temperature measurements.
    # These are device-specific and don't have an effect on this example code.
    cpu_load = 42.0
    display_current = 660.0

    {new_temp_c, new_humid_rh} =
      do_compensate(
        raw_measurement.temperature_c,
        raw_measurement.humidity_rh,
        display_current,
        cpu_load
      )

    %{raw_measurement | temperature_c: new_temp_c, humidity_rh: new_humid_rh}
  end

  @doc """
  Directly call the NIF for compensation

  This function is not intended to be called directly except for test purposes.
  It takes the raw temperature, raw humidity, and the system inputs that affect
  the measurements.

  Returns a tuple with compensated values.
  """
  @spec do_compensate(float(), float(), float(), float()) :: {float(), float()}
  def do_compensate(temp, humidity, display_current, cpu_load) do
    load_nif()
    apply(__MODULE__, :do_compensate, [temp, humidity, display_current, cpu_load])
  end

  @doc """
  Returns the internal compensation state
  """
  @spec get_state() :: state()
  def get_state() do
    load_nif()
    apply(__MODULE__, :get_state, [])
  end

  @doc """
  Set the internal compensation state

  This can be used to restore the state of the compensation algorithm after a
  reboot of the device.  The example compensation algorithm maintains state
  using 25 floats, but this may change depending on the compensation algorithm
  you have. Raises if the right number of floats aren't passed.
  """
  @spec set_state(state()) :: :ok
  def set_state(state) do
    load_nif()
    apply(__MODULE__, :set_state, [state])
  end

  @doc """
  Reset the compensation state

  This is the default starting state, but you may want to call it if something
  is seriously wrong or you want to measure how long the algorithm takes to
  converge on warm boot.
  """
  @spec reset_state() :: :ok
  def reset_state() do
    load_nif()
    apply(__MODULE__, :reset_state, [])
  end

  defp load_nif() do
    nif_binary = Application.app_dir(:example_compensation, "priv/compensation_nif")
    :ok = :erlang.load_nif(to_charlist(nif_binary), 0)
  end
end
