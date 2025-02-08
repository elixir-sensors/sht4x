defmodule SHT4X.MeasurementTest do
  use ExUnit.Case, async: true

  alias SHT4X.Measurement
  doctest Measurement

  test "converts raw measurement" do
    result = Measurement.from_raw(<<101, 233, 109, 229>>)

    assert result.quality == :fresh
    assert result.raw_reading_temperature == 26_089
    assert result.raw_reading_humidity == 28_133

    assert_in_delta result.temperature_c, 24.67, 0.01
    assert_in_delta result.humidity_rh, 47.66, 0.01
    assert_in_delta result.dew_point_c, 12.82, 0.01
  end

  test "detects possible damaged sensor by looking for 0x8000 in both RH and Temp values" do
    result = Measurement.from_raw(<<128, 0, 128, 0>>)
    assert result.quality == :unusable
  end

  test "detects possible damaged sensor by looking for 0x8001 in raw Temp value, and 0x8000 in raw Rh value" do
    result = Measurement.from_raw(<<128, 1, 128, 0>>)
    assert result.quality == :unusable
  end

  test "detects possible damaged sensor by looking for values outside of operating range (Rh)" do
    result = Measurement.from_raw(<<101, 233, 0xFF, 0xFF>>)
    assert result.quality == :unusable
  end

  test "detects possible damaged sensor by looking for values outside of operating range (C)" do
    result = Measurement.from_raw(<<0xFF, 0xFF, 109, 229>>)
    assert result.quality == :unusable
  end

  test "converts boundary values to expected raw values" do
    assert Measurement.humidity_rh_to_raw(0) == 0xC4A
    assert Measurement.humidity_rh_to_raw(100) == 0xD915
    assert Measurement.temperature_c_to_raw(-40) == 0x750
    assert Measurement.temperature_c_to_raw(125) == 0xF8AE
  end
end
