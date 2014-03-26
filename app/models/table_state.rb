class TableState < ActiveRecord::Base
  belongs_to :base, polymorphic: true

  attr_accessible :data,
    :name,
    :base

  validates :name, presence: true
  validates :base, presence: true

  serialize :data, JSON

  before_validation :ensure_json_data


  private
  
  def ensure_json_data
    if !self.data.nil? && !self.data.is_a?(Hash)
      self.data = JSON.parse(self.data)
    end
  rescue JSON::ParserError
    self.data = nil
  end
end
