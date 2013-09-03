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

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email,
    :password,
    :password_confirmation,
    :remember_me,
    :role_ids,
    :name

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
end
