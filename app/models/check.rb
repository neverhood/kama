class Check < ActiveRecord::Base
  belongs_to :website

  default_scope -> { order(:created_at => :desc) }
end
