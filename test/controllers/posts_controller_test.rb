require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    sign_in_as(AuthenticatedUser.new(id: @post.user_id, email_address: @post.user_email, admin: false))
  end

  test "should get index" do
    get posts_url
    assert_response :success
  end

  test "should get new" do
    get new_post_url
    assert_response :success
  end

  test "should create post" do
    assert_difference("Post.count") do
      post posts_url, params: { post: { content: "Some content", title: @post.title } }
    end

    assert_redirected_to post_url(Post.last)
  end

  test "should show post" do
    get post_url(@post)
    assert_response :success
  end

  test "should get edit" do
    get edit_post_url(@post)
    assert_response :success
  end

  test "should update post" do
    patch post_url(@post), params: { post: { content: "Some content", title: @post.title } }
    assert_redirected_to post_url(@post)
  end

  test "should destroy post" do
    assert_difference("Post.count", -1) do
      delete post_url(@post)
    end

    assert_redirected_to posts_url
  end

  test "should not allow a non-author to edit, update, or destroy a post" do
    sign_in_as(AuthenticatedUser.new(id: @post.user_id + 1, email_address: "other@example.com", admin: false))

    get edit_post_url(@post)
    assert_response :forbidden

    patch post_url(@post), params: { post: { content: "Hijacked content", title: @post.title } }
    assert_response :forbidden

    assert_no_difference("Post.count") do
      delete post_url(@post)
    end
    assert_response :forbidden
  end

  test "should allow an admin to edit or update someone else's post" do
    sign_in_as(AuthenticatedUser.new(id: @post.user_id + 1, email_address: "admin@example.com", admin: true))

    get edit_post_url(@post)
    assert_response :success

    patch post_url(@post), params: { post: { content: "Some content", title: @post.title } }
    assert_redirected_to post_url(@post)
  end

  test "should not allow an admin to destroy someone else's post" do
    sign_in_as(AuthenticatedUser.new(id: @post.user_id + 1, email_address: "admin@example.com", admin: true))

    assert_no_difference("Post.count") do
      delete post_url(@post)
    end
    assert_response :forbidden
  end
end
