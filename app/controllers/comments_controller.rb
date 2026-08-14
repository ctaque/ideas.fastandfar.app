class CommentsController < ApplicationController
  before_action :set_post

  # POST /posts/1/comments
  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = Current.user

    if @comment.save
      redirect_to @post, notice: "Comment was successfully added."
    else
      redirect_to @post, alert: @comment.errors.full_messages.to_sentence
    end
  end

  # DELETE /posts/1/comments/1
  def destroy
    @post.comments.find(params.expect(:id)).destroy!
    redirect_to @post, notice: "Comment was successfully destroyed.", status: :see_other
  end

  private
    def set_post
      @post = Post.find(params.expect(:post_id))
    end

    def comment_params
      params.expect(comment: [ :comment ])
    end
end
