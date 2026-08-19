class CommentsController < ApplicationController
  before_action :set_post
  before_action :set_comment, only: %i[ update destroy ]
  before_action :require_author, only: %i[ update destroy ]

  # POST /posts/1/comments
  def create
    @comment = @post.comments.build(comment_params)
    @comment.user_id = Current.user.id
    @comment.user_email = Current.user.email_address
    @comment.user_nickname = Current.user.nickname
    @comment.user_avatar_url = Current.user.avatar_url

    if @comment.save
      MentionNotifier.notify(@comment.comment, post_id: @post.id, comment_id: @comment.id, access_token: cookies[:access_token])
      PostSubscriptionNotifier.notify(@comment, access_token: cookies[:access_token])
      redirect_to @post, notice: "Comment was successfully added."
    else
      redirect_to @post, alert: @comment.errors.full_messages.to_sentence
    end
  end

  # PATCH/PUT /posts/1/comments/1
  def update
    if @comment.update(comment_params.merge(edited_at: Time.current))
      redirect_to @post, notice: "Comment was successfully updated."
    else
      redirect_to @post, alert: @comment.errors.full_messages.to_sentence
    end
  end

  # DELETE /posts/1/comments/1
  def destroy
    @comment.destroy!
    redirect_to @post, notice: "Comment was successfully destroyed.", status: :see_other
  end

  private
    def set_post
      @post = Post.find(params.expect(:post_id))
    end

    def set_comment
      @comment = @post.comments.find(params.expect(:id))
    end

    def require_author
      head :forbidden unless @comment.user_id == Current.user.id
    end

    def comment_params
      params.expect(comment: [ :comment ])
    end
end
