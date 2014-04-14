###
# CacheObserver is an almost-sweeper for handling cache invalidation.
#
# When using touches and updating multiple models simultaneously, this might
# cause multiple unnecessary touches on parent models where one might suffice.
# CacheObserver prevents this by registering which objects were updated and
# doing the touching after the request is processed.
###
class CacheObserver < ActionController::Caching::Sweeper
  observe :activity,
    :evaluation,
    :meeting,
    :participant,
    :result,
    :table_state,
    :student,
    :group

  attr_accessor :changed_models

  # Controller callbacks
  def before(controller)
    self.changed_models = []
    return true
  end
  def after(controller)
    handle_changes()
  end

  # ActiveRecord callback
  def after_save(model)
    if self.changed_models.nil?
      $stderr.puts "\033[31mCacheObserver is running outside a request."
      $stderr.puts "Remember to call CacheObserver.instance.handle_changes if affecting something that needs the cache to be invalidated\033[0m"
      self.changed_models = []
    end

    self.changed_models << model
  end

  alias_method :after_destroy, :after_save


  def handle_changes
    single_models = {}
    evaluations   = []
    students      = []
    groups        = []

    # Register models to be touched
    self.changed_models.each do |model|
      register_touches(model, single_models, evaluations, students, groups)
    end

    # Touch models
    touch_single(single_models)
    touch_for_evaluations(evaluations)
    touch_for_students(students)
    touch_for_groups(groups)

    # Reset changed models
    self.changed_models = nil
  end


  private

  def register_touches(model, single_models, evaluations, students, groups)
    case model
    when Activity, Meeting, Participant
      single_models[Suite] ||= []
      single_models[Suite] << model.suite_id
    when Evaluation
      if model.suite_id
        single_models[Suite] ||= []
        single_models[Suite] << model.suite_id
      end
      evaluations << model.id
    when Result
      single_models[Evaluation] ||= []
      single_models[Evaluation] << model.evaluation_id
      single_models[Student]    ||= []
      single_models[Student]    << model.student_id

      if model.evaluation.suite_id
        single_models[Suite] ||= []
        single_models[Suite] << model.evaluation.suite_id
      end
    when TableState
      single_models[ColorTable] ||= []
      single_models[ColorTable] << model.base_id
    when Student
      students << model.id
    when Group
      groups << model.id
    end
  end

  def touch_single(single_models)
    single_models.each do |klass, ids|
      klass.update_all({ updated_at: timestamp(klass) }, { id: ids.uniq })
    end
  end

  def touch_for_evaluations(evaluations)
    return if evaluations.blank?
    ColorTable.update_all(
      { updated_at: timestamp(ColorTable) },
      [
        "id in (select color_table_id from color_tables_evaluations where evaluation_id in (?))",
        evaluations.uniq
      ]
    )
  end

  def touch_for_students(students)
    return if students.blank?
    students = students.uniq

    conditions = <<-SQL
        id in (
          select color_table_id
          from color_tables_evaluations
          inner join evaluations on evaluations.id = color_tables_evaluations.evaluation_id
          inner join results on results.evaluation_id = evaluations.id
          where results.student_id in (?)
        )
    SQL

    ColorTable.update_all(
      { updated_at: timestamp(ColorTable) },
      [ conditions, students ]
    )

    conditions = <<-SQL
        id in (
          select suite_id
          from participants
          where student_id in (?)
        )
    SQL

    Suite.update_all(
      { updated_at: timestamp(Suite) },
      [ conditions, students ]
    )
  end

  def touch_for_groups(groups)
    return if groups.blank?
    groups = groups.uniq

    conditions = <<-SQL
      id in (
        select participants.suite_id
        from participants
        inner join students on students.id = participants.student_id
        inner join groups_students on groups_students.student_id = students.id
        where groups_students.group_id in (?)
      )
    SQL

    Suite.update_all(
      { updated_at: timestamp(Suite) },
      [ conditions, groups ]
    )
  end


  def timestamp(klass)
    klass.default_timezone == :utc ? Time.now.utc : Time.now
  end
end
