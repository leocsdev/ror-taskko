require "vcr"
require "webmock"

VCR.configure do |config|
  # 1. Directory where recorded YAML files will be saved
  config.cassette_library_dir = "test/vcr_cassettes"

  # 2. Tell VCR to use WebMock to intercept Net::HTTP sockets
  config.hook_into :webmock

  # 3. Security Redaction: Replace the real API key with a placeholder
  config.filter_sensitive_data("<GEMINI_API_KEY>") do
    Rails.application.credentials.dig(:gemini, :api_key) || ENV["GEMINI_API_KEY"]
  end

  # Extra safety: explicitly redact the x-goog-api-key header
  config.before_record do |interaction|
    if interaction.request.headers["x-goog-api-key"]
      interaction.request.headers["x-goog-api-key"] = [ "<GEMINI_API_KEY>" ]
    end
  end

  # 4. Default options:
  # :once means "record it the first time; after that, only read it".
  # If a test tries to make an unexpected new network call, VCR raises an error.
  config.default_cassette_options = {
    record: :once,
    match_requests_on: %i[method uri body]
  }

  # 5. Allow local system tests (Capybara/localhost) to work without interference
  config.ignore_localhost = true
end
