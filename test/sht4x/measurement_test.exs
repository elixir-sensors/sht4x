defmodule SHT4X.MeasurementTest do
  use ExUnit.Case, async: true

  alias SHT4X.Measurement
  doctest Measurement

  test "converts raw measurement" do
    result = Measurement.from_raw(<<101, 233, 234, 109, 229, 160>>)

    assert result.raw_reading_temperature == 26_089
    assert result.raw_reading_humidity == 28_133

    assert_in_delta result.temperature_c, 24.67, 0.01
    assert_in_delta result.humidity_rh, 47.66, 0.01
    assert_in_delta result.dew_point_c, 12.82, 0.01
  end
end
