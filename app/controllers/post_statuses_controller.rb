class PostStatusesController < ApplicationController
  before_action :require_admin
  before_action :set_post

  # PATCH /posts/1/status
  def update
    if @post.update(status: params.expect(:status))
      redirect_back fallback_location: @post, notice: "Status updated."
    else
      redirect_back fallback_location: @post, alert: @post.errors.full_messages.to_sentence
    end
  end

  private
    def set_post
      @post = Post.find(params.expect(:post_id))
    end

    def require_admin
      head :forbidden unless Current.user.admin?
    end
end
