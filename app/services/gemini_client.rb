require "net/http"
require "uri"
require "json"

class GeminiClient
  BASE_URL = "https://generativelanguage.googleapis.com/v1beta/".freeze
  DEFAULT_MODEL = "gemini-2.5-flash".freeze

  # Base error class for all Gemini-related issues
  class Error < StandardError; end

  # Specific error types that inherit from our base error
  class ConfigurationError < Error; end
  class RateLimitError < Error; end
  class TimeoutError < Error; end
  class ApiError < Error; end
  class NetworkError < Error; end
end
