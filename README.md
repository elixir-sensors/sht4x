# SHT4X

[![Hex version](https://img.shields.io/hexpm/v/sht4x.svg 'Hex version')](https://hex.pm/packages/sht4x)
[![CI](https://github.com/elixir-sensors/sht4x/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/elixir-sensors/sht4x/actions/workflows/ci.yml)

Read temperature and humidity from [Sensirion SHT4x sensors](https://www.sensirion.com/en/environmental-sensors) in Elixir.

## Usage

```elixir
iex> {:ok, sht} = SHT4X.start_link(bus_name: "i2c-1")
{:ok, #PID<0.2190.0>}

iex> SHT4X.measure(sht)
{:ok,
  %SHT4X.Measurement{
    timestamp_ms: 498436,
    raw_reading_humidity: 28080,
    raw_reading_temperature: 26379,
    temperature_c: 22.38528060913086,
    humidity_rh: 57.131805419921875,
    dew_point_c: 13.492363250293858
  }}
```

For details, see [API reference](https://hexdocs.pm/sht4x/api-reference.html).
