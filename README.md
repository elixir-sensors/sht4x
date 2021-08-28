# SHT4X

[![Hex version](https://img.shields.io/hexpm/v/sht4x.svg "Hex version")](https://hex.pm/packages/sht4x)
[![CI](https://github.com/mnishiguchi/sht4x/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/mnishiguchi/sht4x/actions/workflows/ci.yml)

Read temperature and pressure from [Sensirion SHT4x
sensors](https://www.sensirion.com/en/environmental-sensors) in Elixir.

## Usage

```elixir
iex> {:ok, sht} = SHT4X.start_link(bus_name: "i2c-1")
{:ok, #PID<0.2190.0>}

iex> SHT4X.measure(sht)
{:ok,
 %SHT4X.Measurement{
   humidity_rh: 58.1079439680166,
   temperature_c: 31.108203375347145,
   timestamp_ms: 184143
 }}
```
