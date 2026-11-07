require "test_helper"

class GeminiClientTest < ActiveSupport::TestCase
  test "initializes with default model and credentials from Rails credentials" do
    client = GeminiClient.new

    assert_equal "gemini-3.6-flash", client.model
    assert_not_empty client.api_key
  end
end
