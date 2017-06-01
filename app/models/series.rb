class Series < ActiveRecord::Base
  belongs_to :suite
  has_many   :evaluations, order: "date asc", dependent: :nullify
  has_many   :results, through: :evaluations

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
    destroy if !self.evaluations || self.evaluations.empty?
  end


  def result_for(student)
    results.where(student_id: student, absent: false).order("evaluations.date desc").first
  end
end
