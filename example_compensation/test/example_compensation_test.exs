# SPDX-FileCopyrightText: 2023 Digit
# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule ExampleCompensationTest do
  use ExUnit.Case
  doctest ExampleCompensation

  defp new_state(temperature_offset, humidity_offset) do
    # See the sht_compensation.c for how the example compensator adds the first state
    # entry to the temperature and the second to the humidity.
    <<temperature_offset::native-float-32, humidity_offset::native-float-32,
      0::integer-size(736)>>
  end

  defp new_measurement(temperature_c, humidity_rh) do
    %SHT4X.Measurement{
      temperature_c: :erlang.float(temperature_c),
      humidity_rh: :erlang.float(humidity_rh),
      raw_reading_temperature: 0,
      raw_reading_humidity: 0,
      timestamp_ms: 0,
      quality: :fresh
    }
  end

  test "setting and getting state" do
    state = new_state(-1, 1)

    assert :ok = ExampleCompensation.set_state(state)
    assert state == ExampleCompensation.get_state()
  end

  test "reseting state" do
    # Disturb state and then reset
    assert :ok = ExampleCompensation.set_state(new_state(1, 1))
    assert :ok = ExampleCompensation.reset_state()

    input = new_measurement(23, 50)
    assert input == ExampleCompensation.compensate(input)
  end

  test "compensation can adjust temperatures" do
    assert :ok = ExampleCompensation.set_state(new_state(-1, 1))

    input = new_measurement(23, 50)
    expected = new_measurement(22, 51)
    assert expected == ExampleCompensation.compensate(input)
  end

  test "setting bad state raises" do
    assert_raise ArgumentError, fn -> ExampleCompensation.set_state(nil) end
    assert_raise ArgumentError, fn -> ExampleCompensation.set_state(List.duplicate(0.0, 24)) end
    assert_raise ArgumentError, fn -> ExampleCompensation.set_state(List.duplicate(0, 25)) end
  end

  test "sending bad values to compensate" do
    # Test sending an integer on accident as one of the parameters
    assert_raise ArgumentError, fn -> ExampleCompensation.do_compensate(1, 2.0, 3.0, 4.0) end
    assert_raise ArgumentError, fn -> ExampleCompensation.do_compensate(1.0, 2, 3.0, 4.0) end
    assert_raise ArgumentError, fn -> ExampleCompensation.do_compensate(1.0, 2.0, 3, 4.0) end
    assert_raise ArgumentError, fn -> ExampleCompensation.do_compensate(1.0, 2.0, 3.0, 4) end
  end
end
