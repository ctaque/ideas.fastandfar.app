require "test_helper"

class PostStatusesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
  end

  test "admin can update a post's status" do
    sign_in_as(AuthenticatedUser.new(id: 999, email_address: "admin@example.com", admin: true))

    patch post_status_url(@post), params: { status: "planned" }

    assert_redirected_to @post
    assert_equal "planned", @post.reload.status
  end

  test "non-admin cannot update a post's status" do
    sign_in_as(AuthenticatedUser.new(id: @post.user_id, email_address: @post.user_email, admin: false))

    patch post_status_url(@post), params: { status: "planned" }

    assert_response :forbidden
    assert_equal "open", @post.reload.status
  end

  test "rejects an invalid status" do
    sign_in_as(AuthenticatedUser.new(id: 999, email_address: "admin@example.com", admin: true))

    patch post_status_url(@post), params: { status: "not-a-real-status" }

    assert_redirected_to @post
    assert_equal "open", @post.reload.status
  end
end
