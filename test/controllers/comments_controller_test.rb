require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    @comment = comments(:one)
    sign_in_as(AuthenticatedUser.new(id: @comment.user_id, email_address: @comment.user_email, admin: false))
  end

  test "should create comment" do
    assert_difference("Comment.count") do
      post post_comments_url(@post), params: { comment: { comment: "Some content" } }
    end

    assert_redirected_to post_url(@post)
  end

  test "should update comment" do
    patch post_comment_url(@post, @comment), params: { comment: { comment: "Updated content" } }
    assert_redirected_to post_url(@post)
    assert_equal "Updated content", @comment.reload.comment.to_plain_text.strip
  end

  test "should destroy comment" do
    assert_difference("Comment.count", -1) do
      delete post_comment_url(@post, @comment)
    end

    assert_redirected_to post_url(@post)
  end

  test "should not allow a non-author to update or destroy a comment" do
    sign_in_as(AuthenticatedUser.new(id: @comment.user_id + 1, email_address: "other@example.com", admin: false))

    patch post_comment_url(@post, @comment), params: { comment: { comment: "Hijacked content" } }
    assert_response :forbidden

    assert_no_difference("Comment.count") do
      delete post_comment_url(@post, @comment)
    end
    assert_response :forbidden
  end

  test "should not allow an admin to update or destroy someone else's comment" do
    sign_in_as(AuthenticatedUser.new(id: @comment.user_id + 1, email_address: "admin@example.com", admin: true))

    patch post_comment_url(@post, @comment), params: { comment: { comment: "Moderated content" } }
    assert_response :forbidden

    assert_no_difference("Comment.count") do
      delete post_comment_url(@post, @comment)
    end
    assert_response :forbidden
  end
end
