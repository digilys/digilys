class User < ActiveRecord::Base
  rolify

  devise :"#{Conf.yubikey ? "yubikey_" : ""}database_authenticatable",
    :registerable,
    :rememberable,
    :trackable,
    :validatable

  has_and_belongs_to_many :groups,     order: "groups.name asc"
  has_and_belongs_to_many :activities
  has_and_belongs_to_many :evaluations

  has_many :settings, as: :customizer, dependent: :destroy

  belongs_to :active_instance, class_name: "Instance"

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email,
    :password,
    :password_confirmation,
    :remember_me,
    :role_ids,
    :name,
    :active_instance_id

  validates :name, presence: true

  # Yubikey specific functionality
  if Conf.yubikey
    attr_accessible :use_yubikey, :registered_yubikey, :yubiotp

    validates :registered_yubikey, presence: true

    attr_accessor :yubiotp

    def registered_yubikey=(yubiotp)
      write_attribute(:registered_yubikey, yubiotp[0..11])
    end
  end


  def self.visible
    where(invisible: false)
  end


  def save_setting!(customizable, data)
    setting   = self.settings.for(customizable).first
    setting ||= self.settings.build(customizable: customizable, data: {})

    setting.data.merge!(data)

    setting.save!
  end
end
