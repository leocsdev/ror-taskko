require "test_helper"

class GeminiClientTest < ActiveSupport::TestCase
  include WebMock::API

  # Wipes all stub_request definitions after each test
  teardown do
    WebMock.reset!
  end

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

  test "inspect masks the api_key to prevent leaking secrets in logs" do
    client = GeminiClient.new(api_key: "super_secret_test_key_12345")

    # 1. Verify the placeholder is shown
    assert_includes client.inspect, 'api_key="[FILTERED]"'

    # 2. Verify the raw secret NEVER appears in the string
    assert_not_includes client.inspect, "super_secret_test_key_12345"
  end

  test "generate_content raises ArgumentError when prompt is blank" do
    client = GeminiClient.new

    assert_raises(ArgumentError) { client.generate_content("") }
    assert_raises(ArgumentError) { client.generate_content("   ") }
    assert_raises(ArgumentError) { client.generate_content(nil) }
  end

  test "generate_content successfully receives and parses a real response from Gemini" do
    VCR.use_cassette("gemini_generate_content_success") do
      client = GeminiClient.new
      prompt = 'Return a JSON object with a single key "status" and value "ok".'

      response_text = client.generate_content(prompt)

      # 1. Verify we got a non-empty string back
      assert_predicate response_text, :present?

      # 2. Parse the JSON returned by Gemini to verify the structure
      parsed_json = JSON.parse(response_text)
      assert_equal "ok", parsed_json["status"]
    end
  end

  test "generate_content raises RateLimitError when Gemini returns HTTP 429" do
    endpoint = "#{GeminiClient::BASE_URL}/gemini-3.6-flash:generateContent"

    # Tell WebMock to intercept the request and return status 429
    stub_request(:post, endpoint).to_return(
      status: 429,
      body: { error: { message: "Resource has been exhausted" } }.to_json,
      headers: { "Content-Type" => "application/json" }
    )

    client = GeminiClient.new

    error = assert_raises(GeminiClient::RateLimitError) do
      client.generate_content("Analyze this task")
    end

    assert_match(/rate limit exceeded/, error.message)
  end

  test "generate_content raises TimeoutError when request times out" do
    endpoint = "#{GeminiClient::BASE_URL}/gemini-3.6-flash:generateContent"

    # Tell WebMock to instantly simulate a socket timeout
    stub_request(:post, endpoint).to_timeout

    client = GeminiClient.new

    error = assert_raises(GeminiClient::TimeoutError) do
      client.generate_content("Analyze this task")
    end

    assert_match(/timed out/, error.message)
  end

  test "generate_content raises ServiceUnavailableError when Gemini returns HTTP 503" do
    endpoint = "#{GeminiClient::BASE_URL}/gemini-3.6-flash:generateContent"

    stub_request(:post, endpoint).to_return(status: 503)

    client = GeminiClient.new

    error = assert_raises(GeminiClient::ServiceUnavailableError) do
      client.generate_content("Analyze this task")
    end

    assert_match(/high demand/, error.message)
  end

  test "generate_content raises NetworkError when connection fails" do
    endpoint = "#{GeminiClient::BASE_URL}/gemini-3.6-flash:generateContent"

    # Tell WebMock to raise a socket-level error
    stub_request(:post, endpoint).to_raise(SocketError.new("Failed to open TCP connection"))

    client = GeminiClient.new

    error = assert_raises(GeminiClient::NetworkError) do
      client.generate_content("Analyze this task")
    end

    assert_match(/Network error reaching Gemini/, error.message)
  end

  test "generate_content raises ApiError on unexpected HTTP errors" do
    endpoint = "#{GeminiClient::BASE_URL}/gemini-3.6-flash:generateContent"

    stub_request(:post, endpoint).to_return(
      status: 500,
      body: { error: { message: "Internal server error occurred on Gemini" } }.to_json,
      headers: { "Content-Type" => "application/json" }
    )

    client = GeminiClient.new

    error = assert_raises(GeminiClient::ApiError) do
      client.generate_content("Analyze this task")
    end

    assert_match(/HTTP 500/, error.message)
    assert_match(/Internal server error occurred on Gemini/, error.message)
  end

  test "generate_content raises ApiError when Gemini blocks response due to safety" do
    endpoint = "#{GeminiClient::BASE_URL}/gemini-3.6-flash:generateContent"

    # Gemini returns HTTP 200, but text is nil and finishReason is "SAFETY"
    safety_response = {
      candidates: [
        {
          finishReason: "SAFETY"
        }
      ]
    }

    stub_request(:post, endpoint).to_return(
      status: 200,
      body: safety_response.to_json,
      headers: { "Content-Type" => "application/json" }
    )

    client = GeminiClient.new

    error = assert_raises(GeminiClient::ApiError) do
      client.generate_content("Analyze this potentially unsafe task")
    end

    assert_match(/No text generated by Gemini/, error.message)
    assert_match(/finish_reason: SAFETY/, error.message)
  end
end
