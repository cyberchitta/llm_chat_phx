defmodule LlmChat.Contexts.Suggestion do
  @moduledoc false
  def get_default() do
    [
      "Write a message that goes with a kitten gif for a friend on a rough day",
      "Suggest fun activities for a family visiting San Francisco",
      "Explain why popcorn pops to a kid who loves watching it in the microwave",
      "Brainstorm edge cases for a function with birthdate as input, horoscope as output"
    ]
  end
end
