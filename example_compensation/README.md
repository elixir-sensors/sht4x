# SPDX-FileCopyrightText: 2023 Digit
#
# SPDX-License-Identifier: Apache-2.0
#
# Example Compensation NIF

Temperature and humidity compensation alters measurements from SHT4x sensors to
remove unwanted heat from things like a nearby CPU. The algorithms that do this
are proprietary and very specific to the device containing the sensor. This
project shows how to wrap a C-based algorithm so that it can be used by the
SHT4X library.

All compensation details have been removed from this example. However, if you do
work with Sensirion AG to create a compensation algorithm, it is hoped that the
you'll see how to modify this code for your device.

Here's an example usage with the SHT4X library:

```elixir
    {:ok, pid} = SHT4X.start_link(
      bus_name: "i2c-0",
      compensation_callback: &ExampleCompensation.compensate/1,
      measurement_interval: 5_000
    )
```

