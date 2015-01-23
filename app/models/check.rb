class Check < ActiveRecord::Base
  belongs_to :website

  default_scope -> { order(:created_at => :desc) }

  def success?
    # 2x and 3x are considered being successfull
    %(2 3).include? response_code.to_s[0]
  end

  def failure?
    not success?
  end
end
