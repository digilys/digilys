class User < ActiveRecord::Base
  rolify

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :rememberable, :trackable, :validatable

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
end
