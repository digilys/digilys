class User < ActiveRecord::Base
  rolify

  devise :"#{Conf.yubikey ? "yubikey_" : ""}database_authenticatable",
    :trackable,
    :validatable

  has_and_belongs_to_many :groups,     order: "groups.name asc"
  has_and_belongs_to_many :activities
  has_and_belongs_to_many :evaluations
  has_and_belongs_to_many :instances

  has_many :settings, as: :customizer, dependent: :destroy

  belongs_to :admin_instance, class_name: "Instance"
  belongs_to :active_instance, class_name: "Instance"

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email,
    :password,
    :password_confirmation,
    :remember_me,
    :role_ids,
    :name,
    :active_instance_id,
    :admin_instance_id,
    :instance_ids,
    :name_ordering

  validates :name, presence: true
  validates :active_instance, presence: true, on: :create

  serialize :preferences, JSON

  after_create :grant_membership_to_active_instance

  # Yubikey specific functionality
  if Conf.yubikey
    attr_accessible :use_yubikey, :registered_yubikey, :yubiotp

    validates :registered_yubikey, presence: true, uniqueness: true

    attr_accessor :yubiotp

    def registered_yubikey=(yubiotp)
      write_attribute(:registered_yubikey, yubiotp[0..11])
    end
  end

  def self.visible
    where(invisible: false)
  end

  def is_administrator?
    return has_any_role?(:admin, :planner)
  end

  def is_admin_of?(instance)
    return self.admin_instance == instance unless self.admin_instance.nil?
  end

  def save_setting!(customizable, data)
    setting   = self.settings.for(customizable).first
    setting ||= self.settings.build(customizable: customizable, data: {})

    setting.data.merge!(data)

    setting.save!
  end

  def instances
    @instances ||= Instance.with_role(:member, self)
  end

  def name_ordering
    self.preferences ||= {}
    self.preferences["name_ordering"].try(:to_sym) || :first_name
  end
  def name_ordering=(name_ordering)
    self.preferences ||= {}
    self.preferences["name_ordering"] = case name_ordering.try(:to_sym)
    when :first_name then :first_name
    when :last_name  then :last_name
    else
      nil
    end
  end

  private

  def grant_membership_to_active_instance
    self.add_role :member, self.active_instance
  end
end
