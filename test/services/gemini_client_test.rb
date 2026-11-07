require "test_helper"

class GeminiClientTest < ActiveSupport::TestCase
  test "initializes with default model and credentials from Rails credentials" do
    client = GeminiClient.new

    assert_equal "gemini-3.6-flash", client.model
    assert_not_empty client.api_key
  end

  test "allows overriding the model and api_key" do
    client = GeminiClient.new(api_key: "explicit_key", model: "custom-model")

    assert_equal "custom-model", client.model
    assert_equal "explicit_key", client.api_key
  end

  test "raises ConfigurationError when api_key is missing or blank" do
    original_env_key = ENV["GEMINI_API_KEY"]
    begin
      ENV["GEMINI_API_KEY"] = nil
      # 1. Temporarily make Rails.application.credentials return an empty Hash {}
      Rails.application.define_singleton_method(:credentials) { {} }

      # Case A: api_key is nil and no credentials/ENV exist
      error = assert_raises(GeminiClient::ConfigurationError) do
        GeminiClient.new(api_key: nil)
      end

      assert_match(/Gemini API key is missing/, error.message)
      # Case B: api_key is an empty or whitespace string
      assert_raises(GeminiClient::ConfigurationError) do
        GeminiClient.new(api_key: "")
      end
    ensure
      # 2. Restore ENV and remove the singleton method so credentials works normally again
      ENV["GEMINI_API_KEY"] = original_env_key
      Rails.application.singleton_class.send(:remove_method, :credentials) rescue nil
    end
  end
end
