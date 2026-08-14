require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "edit requires authentication" do
    get edit_profile_path
    assert_redirected_to new_session_path
  end

  test "edit" do
    sign_in_as(@user)

    get edit_profile_path
    assert_response :success
  end

  test "update email address" do
    sign_in_as(@user)

    patch profile_path, params: { email_address: "new@example.com", current_password: "password" }

    assert_redirected_to edit_profile_path
    assert_equal "new@example.com", @user.reload.email_address
  end

  test "update password" do
    sign_in_as(@user)

    assert_changes -> { @user.reload.password_digest } do
      patch profile_path, params: { password: "newpassword", password_confirmation: "newpassword", current_password: "password" }
      assert_redirected_to edit_profile_path
    end
  end

  test "update with wrong current password" do
    sign_in_as(@user)

    patch profile_path, params: { email_address: "new@example.com", current_password: "wrong" }

    assert_response :unprocessable_entity
    assert_not_equal "new@example.com", @user.reload.email_address
  end

  test "update with non matching password confirmation" do
    sign_in_as(@user)

    assert_no_changes -> { @user.reload.password_digest } do
      patch profile_path, params: { password: "new", password_confirmation: "mismatch", current_password: "password" }
      assert_response :unprocessable_entity
    end
  end

  test "update with invalid email address" do
    sign_in_as(@user)

    patch profile_path, params: { email_address: "not-an-email", current_password: "password" }

    assert_response :unprocessable_entity
    assert_not_equal "not-an-email", @user.reload.email_address
  end
end
