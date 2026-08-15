# Classifies a comment's text via the Claude API before it's saved. Runs
# synchronously in a model validation, so it's kept to a single small,
# cheap, forced tool-use call (Haiku 4.5 — see the model choice rationale
# in conversation). If the API is unreachable or errors, moderation
# fails open: the comment is allowed through rather than blocking comment
# creation on an Anthropic outage.
class CommentModerator
  MODEL = "claude-haiku-4-5"

  MODERATE_TOOL = {
    name: "moderate_comment",
    description: "Classify a user-submitted blog comment for moderation. Flag comments that are " \
      "abusive, harassing, hateful, sexually explicit, or spam. Do not flag comments merely because " \
      "they are critical, negative, or impolite in an ordinary way.",
    input_schema: {
      type: "object",
      properties: {
        flagged: {
          type: "boolean",
          description: "true if the comment violates the guidelines above and should be blocked"
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
    # (fail open) so moderation downtime never blocks comment creation.
    def call(text)
      response = client.messages.create(
        model: MODEL,
        max_tokens: 200,
        tools: [ MODERATE_TOOL ],
        tool_choice: { type: "tool", name: "moderate_comment" },
        messages: [ { role: "user", content: text } ]
      )

      tool_use = response.content.find { |block| block.type == :tool_use }
      input = tool_use.input

      Result.new(flagged: input["flagged"], category: input["category"], reason: input["reason"])
    rescue Anthropic::Errors::Error => e
      Rails.logger.warn("CommentModerator: Claude API call failed, allowing comment through (#{e.class}: #{e.message})")
      Result.new(flagged: false, category: "none", reason: "moderation unavailable")
    end

    private
      def client
        @client ||= Anthropic::Client.new
      end
  end
end
