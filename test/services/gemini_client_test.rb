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
end
