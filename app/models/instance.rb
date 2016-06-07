class Instance < ActiveRecord::Base
  resourcify

  has_many :students
  has_many :groups
  has_and_belongs_to_many :users

  attr_accessible :name, :user_id

  validates :name, presence: true

  def users_select2_data
    self.users.collect { |u| { id: u.id, text: "#{u.name}, #{u.email}" } }
  end

  def self.authorized_instances(user)
    return Instance.order(:name).all if user.is_administrator?

    return Instance.where(id: user.active_instance).all
  end

  def admins
    User.with_role(:instance_admin, i).all
  end
end
