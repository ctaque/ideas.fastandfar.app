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

  test "should default to is:idea state:open when no query is given" do
    bug = Post.create!(title: "Crash on save", type: "bug", status: "closed",
      user_id: @post.user_id, user_email: @post.user_email)

    get posts_url
    assert_response :success
    assert_includes @response.body, @post.title
    assert_not_includes @response.body, bug.title
  end

  test "should show all posts when the query is explicitly cleared" do
    bug = Post.create!(title: "Crash on save", type: "bug", status: "closed",
      user_id: @post.user_id, user_email: @post.user_email)

    get posts_url(q: "")
    assert_response :success
    assert_includes @response.body, @post.title
    assert_includes @response.body, bug.title
  end

  test "should filter index by is: and state: qualifiers" do
    bug = Post.create!(title: "Crash on save", type: "bug", status: "closed",
      user_id: @post.user_id, user_email: @post.user_email)

    get posts_url(q: "is:bug state:closed")
    assert_response :success
    assert_includes @response.body, bug.title
    assert_not_includes @response.body, @post.title
  end

  test "should filter index by author: qualifier, matching nickname case-insensitively" do
    @post.update!(user_nickname: "Alice")
    other = Post.create!(title: "Someone else's idea", user_id: @post.user_id + 1,
      user_email: "bob@example.com", user_nickname: "bob")

    get posts_url(q: "author:alice")
    assert_response :success
    assert_includes @response.body, @post.title
    assert_not_includes @response.body, other.title
  end

  test "should filter index by author:me, matching the signed-in user by id" do
    other = Post.create!(title: "Someone else's idea", user_id: @post.user_id + 1,
      user_email: "bob@example.com", user_nickname: @post.user_nickname)

    get posts_url(q: "author:me")
    assert_response :success
    assert_includes @response.body, @post.title
    assert_not_includes @response.body, other.title
  end

  test "should filter index by title text alongside qualifiers" do
    get posts_url(q: "is:idea #{@post.title}")
    assert_response :success
    assert_includes @response.body, @post.title
  end

  test "should ignore unknown qualifier values" do
    get posts_url(q: "is:not-a-type state:not-a-state")
    assert_response :success
    assert_includes @response.body, @post.title
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
