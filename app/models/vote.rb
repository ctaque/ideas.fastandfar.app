class Vote < ApplicationRecord
  belongs_to :post

  validates :user_id, :user_email, presence: true
  validates :value, inclusion: { in: [ 1, -1 ] }
  validates :user_id, uniqueness: { scope: :post_id }
end
