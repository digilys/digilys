require "yajl"

class Digilys::Exporter
  def initialize(id_prefix)
    @id_prefix = id_prefix
    @encoder = Yajl::Encoder.new(pretty: true)
  end

  def export_instances(io)
    Instance.order(:id).find_each do |instance|
      @encoder.encode(id_filter(instance.attributes), io)
    end
  end

  def export_users(io)
    User.order(:id).find_each do |user|
      @encoder.encode(id_filter(user.attributes), io)
    end
  end

  def export_students(io)
    Student.order(:id).find_each do |student|
      attributes                = id_filter(student.attributes)
      attributes["personal_id"] = attributes.delete("_personal_id")

      @encoder.encode(attributes, io)
    end
  end

  def export_groups(io)
    Group.order(:id).find_each do |group|
      attributes              = id_filter(group.attributes)
      attributes["_students"] = group.student_ids.collect { |i| prefix_id(i) }
      attributes["_users"]    = group.user_ids.collect    { |i| prefix_id(i) }

      @encoder.encode(attributes, io)
    end
  end

  def export_instructions(io)
    Instruction.order(:id).find_each do |instruction|
      @encoder.encode(id_filter(instruction.attributes), io)
    end
  end

  def export_suites(io)
    Suite.order(:id).find_each do |suite|
      attributes = id_filter(suite.attributes)

      if attributes["generic_evaluations"]
        attributes["generic_evaluations"] = attributes["generic_evaluations"].collect { |i| prefix_id(i) }
      end

      @encoder.encode(attributes, io)
    end
  end

  def export_participants(io)
    Participant.order(:id).find_each do |participant|
      @encoder.encode(id_filter(participant.attributes), io)
    end
  end

  def export_meetings(io)
    Meeting.order(:id).find_each do |meeting|
      @encoder.encode(id_filter(meeting.attributes), io)
    end
  end

  def export_activities(io)
    Activity.order(:id).find_each do |activity|
      attributes = id_filter(activity.attributes)
      attributes["_groups"]   = activity.group_ids.collect   { |i| prefix_id(i) }
      attributes["_students"] = activity.student_ids.collect { |i| prefix_id(i) }
      attributes["_users"]    = activity.user_ids.collect    { |i| prefix_id(i) }

      @encoder.encode(attributes, io)
    end
  end

  def export_generic_evaluations(io)
    Evaluation.with_type(:generic).order(:id).find_each do |generic_evaluation|
      attributes = id_filter(generic_evaluation.attributes)
      attributes["category_list"] = generic_evaluation.category_list

      @encoder.encode(attributes, io)
    end
  end

  def export_evaluation_templates(io)
    Evaluation.with_type(:template).order(:id).find_each do |evaluation_template|
      attributes = id_filter(evaluation_template.attributes)
      attributes["category_list"] = evaluation_template.category_list

      @encoder.encode(attributes, io)
    end
  end

  def export_suite_evaluations(io)
    Evaluation.with_type(:suite).order(:id).find_each do |suite_evaluation|
      attributes = id_filter(suite_evaluation.attributes)
      attributes["category_list"] = suite_evaluation.category_list
      attributes["_participants"] = suite_evaluation.evaluation_participant_ids.collect { |i| prefix_id(i) }
      attributes["_users"]        = suite_evaluation.user_ids.collect                   { |i| prefix_id(i) }

      @encoder.encode(attributes, io)
    end
  end

  def export_results(io)
    Result.order(:id).find_each do |result|
      @encoder.encode(id_filter(result.attributes), io)
    end
  end

  private

  def id_filter(hash)
    hash.inject({}) do |h, (k,v)|
      if k =~ /^(id|.+_id)$/
        h["_#{k}"] = v.nil? ? nil : prefix_id(v)
      else
        h[k] = v
      end
      h
    end
  end

  def prefix_id(i)
    "#{@id_prefix}-#{i}"
  end
end
