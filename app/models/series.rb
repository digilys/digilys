class Series < ActiveRecord::Base
  belongs_to :suite
  has_many   :evaluations, order: "date asc", dependent: :nullify

  attr_accessible :name,
    :suite,
    :suite_id

  validates :name, presence: true, uniqueness: { scope: :suite_id }
end
