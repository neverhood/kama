class Recipient < ActiveRecord::Base
  validates :name, :email, presence: true
  validates :email, uniqueness: true, email: true, if: -> { email.present? }

  default_scope -> { order(:created_at => :desc) }
end
