# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.1] - 2025-03-08

### Changed

* Update copyrights and license info for REUSE compliance

## [0.3.0] - 2024-02-11

### Changed

* Changed error returns to return `{:error, reason}` rather than just `:error`.
  This is a backwards incompatible change if your code matches on `:error`.
* Changed retry semantics to only retry on CRC mismatch errors. Previously, CRC
  mismatches were not retried and retries were done at the I2C transaction
  level. Retrying on the I2C level wasn't effective and ended up causing long
  delays. So far, CRC errors are the ones worth retrying since they happen rare
  enough that a retry is pretty much guaranteed to work.

## [0.2.3] - 2024-01-16

### Changed

* Updated dependencies.
* `circuits_i2c` - either version 1.x or 2.x can now be used with this library.

## [0.2.2] - 2023-11-28

### Changed

* Flag bad values from the SHT4X so that they aren't used. Bad values include
  the 0x8000/0x8000 bad report and values outside of 0-100 RH and -40-125C
* Add `SHT4X.soft_reset/1`

## [0.2.1] - 2023-08-30

### Bug Fixes
* `SHT4X.Measurement`'s types have been updated to ensure `:humidity_rh` and `:temperature_c` are `float()`
* The hard-coded `:unusable` measurement value has been updated to return floats as expected.

## [0.2.0] - 2023-07-14

### Changed

* SHT4X regularly polls temperature and humidity at 5 second intervals
  (configurable). Regular polling is required for temperature compensation
  algorithms.
* The `SHT4X.measure/1` function is now `SHT4X.get_sample/1` to reflect that it
  returns the latest sample rather than polling the sensor. The `SHT4X.Measurement`
  struct contains a timestamp and quality information to indicate how stale it
  is. Staleness could be due to communication issues with the sensor or just
  waiting for the next poll time.
* The sensor's serial number is not polled on init. This means that I2C failures
  or retry delays won't delay or fail startup. They likely will affect the
  regular polling if they don't resolve themselves.

### Added

* `SHT4X.serial_number/1` to get the sensor's unique serial number
* The sensor is immediately polled for a temperature. Previously the first
  temperature measurement was delayed until the interval timer expired (default 5
  seconds).

## [0.1.4] - 2023-02-01
### Improvements
* Catch errors from the transport initialization (thanks to @doawoo)

## [0.1.3] - 2022-12-10
### Improvements
* Correct typespecs
* Change use Bitwise to import Bitwise per warning
* Improve docs
* Allow users to pass in a `:retries` option for the I2C transport (thank you @doawoo)
* Update dependencies

## [0.1.2] - 2022-02-11
### Improvements
- Simplified the transport-related code
- Refactor the top-level module

### Added
- `typed_struct`
- `circuit_i2c`

### Removed
- `i2c_server`
- `mox`

## [0.1.1] - 2021-08-27
### Added
- Derived `dew_point_c` value

## [0.1.0] - 2021-08-23
### Added
- Initial release

[0.3.0]: https://github.com/elixir-sensors/sht4x/compare/v0.2.3..v0.3.0
[0.2.3]: https://github.com/elixir-sensors/sht4x/compare/v0.2.2..v0.2.3
[0.2.2]: https://github.com/elixir-sensors/sht4x/compare/v0.2.1..v0.2.2
[0.2.1]: https://github.com/elixir-sensors/sht4x/compare/v0.2.0..v0.2.1
[0.2.0]: https://github.com/elixir-sensors/sht4x/compare/v0.1.4..v0.2.0
[0.1.4]: https://github.com/elixir-sensors/sht4x/compare/v0.1.3..v0.1.4
[0.1.3]: https://github.com/elixir-sensors/sht4x/compare/v0.1.2..v0.1.3
[0.1.2]: https://github.com/elixir-sensors/sht4x/compare/v0.1.1..v0.1.2
[0.1.1]: https://github.com/elixir-sensors/sht4x/compare/v0.1.0..v0.1.1
[0.1.0]: https://github.com/elixir-sensors/sht4x/releases/tag/v0.1.0
