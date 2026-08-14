class ProfilesController < ApplicationController
  before_action :set_user

  def edit
  end

  def update
    unless @user.authenticate(params[:current_password])
      @user.errors.add(:current_password, "is incorrect")
      return render :edit, status: :unprocessable_entity
    end

    if @user.update(profile_params)
      redirect_to edit_profile_path, notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_user
      @user = Current.user
    end

    def profile_params
      params.permit(:email_address, :password, :password_confirmation).tap do |permitted|
        permitted.delete(:password) if permitted[:password].blank?
        permitted.delete(:password_confirmation) if permitted[:password_confirmation].blank?
      end
    end
end
