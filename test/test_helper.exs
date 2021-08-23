# Always warning as errors
if Version.match?(System.version(), "~> 1.10") do
  Code.put_compiler_option(:warnings_as_errors, true)
end

# Define dynamic mocks
Mox.defmock(SHT4X.MockTransport, for: SHT4X.Transport)

# Override the config settings
Application.put_env(:sht4x, :transport_mod, SHT4X.MockTransport)

ExUnit.start()
