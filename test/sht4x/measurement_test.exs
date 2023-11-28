defmodule SHT4X.MeasurementTest do
  use ExUnit.Case, async: true

  alias SHT4X.Measurement
  doctest Measurement

  test "converts raw measurement" do
    result = Measurement.from_raw(<<101, 233, 234, 109, 229, 160>>)

    assert result.quality == :fresh
    assert result.raw_reading_temperature == 26_089
    assert result.raw_reading_humidity == 28_133

    assert_in_delta result.temperature_c, 24.67, 0.01
    assert_in_delta result.humidity_rh, 47.66, 0.01
    assert_in_delta result.dew_point_c, 12.82, 0.01
  end

  test "detects possible damaged sensor by looking for 0x8000 in both RH and Temp values" do
    result = Measurement.from_raw(<<128, 0, 162, 128, 0, 162>>)
    assert result.quality == :unusable
  end

  test "detects possible damaged sensor by looking for 0x8001 in raw Temp value, and 0x8000 in raw Rh value" do
    result = Measurement.from_raw(<<128, 1, 162, 128, 0, 162>>)
    assert result.quality == :unusable
  end

  test "detects possible damaged sensor by looking for values outside of operating range (Rh)" do
    result = Measurement.from_raw(<<101, 233, 234, 0xFF, 0xFF, 172>>)
    assert result.quality == :unusable
  end

  test "detects possible damaged sensor by looking for values outside of operating range (C)" do
    result = Measurement.from_raw(<<0xFF, 0xFF, 172, 109, 229, 160>>)
    assert result.quality == :unusable
  end
end
