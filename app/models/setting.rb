class Setting < ActiveRecord::Base

  belongs_to :customizer,   polymorphic: true
  belongs_to :customizable, polymorphic: true

  attr_accessible :data,
    :customizer,
    :customizable

  serialize :data, JSON

  # Filters on a specific customizable. Preferrably used in a +has_many+ association:
  #
  #   user.settings.for(suite)
  #
  def self.for(customizable)
    where(customizable_id: customizable.id, customizable_type: customizable.class.base_class.name)
  end
end
