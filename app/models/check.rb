class Check < ActiveRecord::Base
  belongs_to :website

  default_scope -> { order(:created_at => :desc) }

  def success?
    response_code.to_s[0] == "2"
  end
end
