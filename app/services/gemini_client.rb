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

  attr_reader :api_key, :model

  def initialize(api_key: nil, model: DEFAULT_MODEL)
    @api_key = api_key || Rails.application.credentials.dig(:gemini, :api_key) ||
      ENV["GEMINI_API_KEY"]
    @model = model

    validate_configuration!
  end

  # Custom inspect to avoid leaking API keys in logs/debugging
  def inspect
    "#<#{self.class.name} model=#{model.inspect} api_key=\"[FILTERED]\">"
  end

  private

  def validate_configuration!
    if @api_key.blank?
      raise ConfigurationError, "Gemini API key is missing. Set it in Rails credentials (gemini.api_key) or ENV['GEMINI_API_KEY']."
    end
  end
end
