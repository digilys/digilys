class Instruction < ActiveRecord::Base
  attr_accessible :body,
    :for_page,
    :title

  validates :title,    presence: true
  validates :for_page, presence: true

  def self.for_controller_action(controller, action)
    where(for_page: "#{controller}/#{action}").first
  end
end
