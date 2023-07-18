import Config

# Simulate an SHT4X on i2c-1
config :circuits_sim,
  config: [
    {CircuitsSim.Device.SHT4X, bus_name: "i2c-1", address: 0x44, serial_number: 0x87654321}
  ]

# Enable simulated I2C as the default
config :circuits_i2c, default_backend: CircuitsSim.I2C.Backend
