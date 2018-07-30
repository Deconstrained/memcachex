Code.require_file("./test_utils.exs", __DIR__)
ExUnit.start(capture_log: true)

defmodule Test.KeyCoder do
  def call(key) do
    "app:#{key}"
  end
end
