# Classifies a post's title and content via the Claude API before it's
# saved. Runs synchronously in a model validation, so it's kept to a
# single small, cheap, forced tool-use call (Haiku 4.5 — see the model
# choice rationale in conversation). If the API is unreachable or
# errors, moderation fails open: the post is allowed through rather
# than blocking post creation on an Anthropic outage.
class PostModerator
  MODEL = "claude-haiku-4-5"

  MODERATE_TOOL = {
    name: "moderate_post",
    description: "Classify a user-submitted idea's title and content for moderation. Flag content that is " \
      "abusive, harassing, hateful, sexually explicit, or spam. Do not flag content merely because " \
      "it is critical, negative, or impolite in an ordinary way.",
    input_schema: {
      type: "object",
      properties: {
        flagged: {
          type: "boolean",
          description: "true if the title or content violates the guidelines above and should be blocked"
        },
        category: {
          type: "string",
          enum: %w[ none harassment hate sexual spam ],
          description: "Primary violation category, or \"none\" if not flagged"
        },
        reason: {
          type: "string",
          description: "One short sentence explaining the decision"
        }
      },
      required: %w[ flagged category reason ]
    }
  }.freeze

  Result = Data.define(:flagged, :category, :reason)

  class << self
    # Returns a Result. On any API failure, returns a non-flagged Result
    # (fail open) so moderation downtime never blocks post creation.
    def call(title, content)
      response = client.messages.create(
        model: MODEL,
        max_tokens: 200,
        tools: [ MODERATE_TOOL ],
        tool_choice: { type: "tool", name: "moderate_post" },
        messages: [ { role: "user", content: "Title: #{title}\n\nContent: #{content}" } ]
      )

      tool_use = response.content.find { |block| block.type == :tool_use }
      input = tool_use.input

      Result.new(flagged: input[:flagged], category: input[:category], reason: input[:reason])
    rescue Anthropic::Errors::Error => e
      Rails.logger.warn("PostModerator: Claude API call failed, allowing post through (#{e.class}: #{e.message})")
      Result.new(flagged: false, category: "none", reason: "moderation unavailable")
    end

    private
      def client
        @client ||= Anthropic::Client.new
      end
  end
end
