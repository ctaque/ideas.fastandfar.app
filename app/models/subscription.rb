class Subscription < ApplicationRecord
  belongs_to :post

  validates :user_id, :user_email, presence: true
  validates :user_id, uniqueness: { scope: :post_id }
end
