defmodule SHT4XTest do
  use ExUnit.Case
  doctest SHT4X

  alias CircuitsSim.Device.SHT4X, as: SHT4XSim

  @i2c_bus "i2c-1"
  @i2c_address 0x44

  setup do
    SHT4XSim.inject_crc_errors(@i2c_bus, @i2c_address, 0)
  end

  test "reading the temperature and humidity via the simulator" do
    sht_pid = start_supervised!(SHT4X)

    SHT4XSim.set_temperature_c(@i2c_bus, @i2c_address, 11.1)
    SHT4XSim.set_humidity_rh(@i2c_bus, @i2c_address, 33.3)

    measurement = SHT4X.get_sample(sht_pid)
    assert measurement.quality == :fresh
    assert_in_delta measurement.humidity_rh, 33.3, 0.1
    assert_in_delta measurement.temperature_c, 11.1, 0.1
  end

  test "recovers from one crc error" do
    sht_pid = start_supervised!(SHT4X)

    SHT4XSim.set_temperature_c(@i2c_bus, @i2c_address, 11.1)
    SHT4XSim.set_humidity_rh(@i2c_bus, @i2c_address, 33.3)
    SHT4XSim.inject_crc_errors(@i2c_bus, @i2c_address, 1)

    measurement = SHT4X.get_sample(sht_pid)
    assert measurement.quality == :fresh
    assert_in_delta measurement.humidity_rh, 33.3, 0.1
    assert_in_delta measurement.temperature_c, 11.1, 0.1
  end

  test "fails on crc errors on two transactions" do
    sht_pid = start_supervised!(SHT4X)

    SHT4XSim.set_temperature_c(@i2c_bus, @i2c_address, 11.1)
    SHT4XSim.set_humidity_rh(@i2c_bus, @i2c_address, 33.3)

    # Each transaction gets 2 CRC errors. 1 try + 2 retries = 3 transactions
    # that need to be messed up.  Therefore, 5 or more CRC errors are needed.
    SHT4XSim.inject_crc_errors(@i2c_bus, @i2c_address, 5)

    measurement = SHT4X.get_sample(sht_pid)
    assert measurement.quality == :unusable
  end

  test "reading the simulated serial number" do
    sht_pid = start_supervised!(SHT4X)

    # See config.exs for where the serial number is set in the simulator
    assert SHT4X.serial_number(sht_pid) == {:ok, 0x87654321}
  end

  defp add_degree(measurement) do
    %{measurement | temperature_c: measurement.temperature_c + 1}
  end

  test "compensation callback gets called" do
    sht_pid = start_supervised!({SHT4X, compensation_callback: &add_degree/1})

    SHT4XSim.set_temperature_c(@i2c_bus, @i2c_address, 20)

    measurement = SHT4X.get_sample(sht_pid)
    assert_in_delta measurement.temperature_c, 21.0, 0.1
  end
end
