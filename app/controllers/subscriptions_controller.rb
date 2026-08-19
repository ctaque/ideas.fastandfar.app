class SubscriptionsController < ApplicationController
  before_action :set_post

  # POST /posts/1/subscription
  def create
    subscription = @post.subscriptions.find_or_initialize_by(user_id: Current.user.id)

    if subscription.persisted?
      subscription.destroy!
    else
      subscription.user_email = Current.user.email_address
      subscription.save!
    end

    redirect_back fallback_location: @post
  end

  private
    def set_post
      @post = Post.find(params.expect(:post_id))
    end
end
