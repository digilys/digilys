class Series < ActiveRecord::Base
  belongs_to :suite
  has_many   :evaluations, order: "date asc", dependent: :nullify

  attr_accessible :name,
    :suite,
    :suite_id

  validates :name, presence: true, uniqueness: { scope: :suite_id }

  def current_evaluation
    self.evaluations.with_status(:partial, :complete).reorder("date desc").first
  end

  def update_current!
    self.evaluations.update_all(is_series_current: false)
    if current = self.current_evaluation
      current.update_attribute(:is_series_current, true)
    end
  end

  def destroy_on_empty!
    destroy if self.evaluations.empty?
  end
end
