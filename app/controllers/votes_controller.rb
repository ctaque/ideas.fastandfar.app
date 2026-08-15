class VotesController < ApplicationController
  before_action :set_post

  # POST /posts/1/vote
  def create
    unless [ 1, -1 ].include?(vote_value)
      return redirect_back fallback_location: @post, alert: "Invalid vote."
    end

    vote = @post.votes.find_or_initialize_by(user_id: Current.user.id)

    if vote.value == vote_value
      vote.destroy!
    else
      vote.user_email = Current.user.email_address
      vote.update!(value: vote_value)
    end

    redirect_back fallback_location: @post
  end

  private
    def set_post
      @post = Post.find(params.expect(:post_id))
    end

    def vote_value
      params.expect(:value).to_i
    end
end
