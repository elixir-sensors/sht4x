# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/elixir-sensors/sht4x/compare/v0.1.4..HEAD
[0.1.4]: https://github.com/elixir-sensors/sht4x/compare/v0.1.3..v0.1.4
[0.1.3]: https://github.com/elixir-sensors/sht4x/compare/v0.1.2..v0.1.3
[0.1.2]: https://github.com/elixir-sensors/sht4x/compare/v0.1.1..v0.1.2
[0.1.1]: https://github.com/elixir-sensors/sht4x/compare/v0.1.0..v0.1.1
[0.1.0]: https://github.com/elixir-sensors/sht4x/releases/tag/v0.1.0
