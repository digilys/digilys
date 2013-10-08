require "yajl"

class Digilys::Importer
  def initialize(id_prefix)
    @id_prefix = id_prefix
    @parser    = Yajl::Parser.new
    @mappings  = Hash.new { |h,k| h[k] = {} }
  end

  attr_reader :mappings

  def mappings=(hash)
    hash.default_proc = @mappings.default_proc
    @mappings         = hash
  end


  def import_instances(io)
    @parser.on_parse_complete = method(:handle_instance_object)
    @parser.parse(io)
  end
  def import_users(io)
    @parser.on_parse_complete = method(:handle_user_object)
    @parser.parse(io)
  end
  def import_students(io)
    @parser.on_parse_complete = method(:handle_student_object)
    @parser.parse(io)
  end
  def import_groups(io)
    @parser.on_parse_complete = method(:handle_group_object)
    @parser.parse(io)

    io.rewind

    @parser.on_parse_complete = method(:handle_group_object_for_hierarchy)
    @parser.parse(io)
  end
  def import_instructions(io)
    @parser.on_parse_complete = method(:handle_instruction_object)
    @parser.parse(io)
  end
  def import_suites(io)
    @parser.on_parse_complete = method(:handle_suite_object)
    @parser.parse(io)

    io.rewind

    @parser.on_parse_complete = method(:handle_suite_object_for_hierarchy)
    @parser.parse(io)
  end
  def import_participants(io)
    @parser.on_parse_complete = method(:handle_participant_object)
    @parser.parse(io)
  end
  def import_meetings(io)
    @parser.on_parse_complete = method(:handle_meeting_object)
    @parser.parse(io)
  end
  def import_activities(io)
    @parser.on_parse_complete = method(:handle_activity_object)
    @parser.parse(io)
  end
  def import_generic_evaluations(io)
    @parser.on_parse_complete = method(:handle_generic_evaluation_object)
    @parser.parse(io)

    Suite.find_each do |suite|
      if suite.generic_evaluations.any? { |i| i =~ /^#{@id_prefix}/ }
        suite.generic_evaluations = suite.generic_evaluations.collect { |id| mappings["generic_evaluations"][id] || id }
        suite.save
      end
    end
  end
  def import_evaluation_templates(io)
    @parser.on_parse_complete = method(:handle_evaluation_template_object)
    @parser.parse(io)

    io.rewind

    @parser.on_parse_complete = method(:handle_evaluation_template_object_for_hierarchy)
    @parser.parse(io)
  end
  def import_suite_evaluations(io)
    @parser.on_parse_complete = method(:handle_suite_evaluation_object)
    @parser.parse(io)
  end
  def import_results(io)
    @parser.on_parse_complete = method(:handle_result_object)
    @parser.parse(io)
  end
  def import_settings(io)
    @parser.on_parse_complete = method(:handle_setting_object)
    @parser.parse(io)
  end
  def import_table_states(io)
    @parser.on_parse_complete = method(:handle_table_state_object)
    @parser.parse(io)
  end
  def import_roles(io)
    @parser.on_parse_complete = method(:handle_role_object)
    @parser.parse(io)
  end


  def handle_instance_object(obj)
    attributes, meta = partition_object(obj)
    _id              = meta["_id"]

    return if mappings["instances"].has_key?(_id) && Instance.exists?(mappings["instances"][_id])

    instance = Instance.new do |i|
      attributes.each { |k, v| i[k] = v }
    end
    instance.save!

    mappings["instances"][_id] = instance.id

    return instance
  end

  def handle_user_object(obj)
    attributes, meta = partition_object(obj)
    _id              = meta["_id"]

    return if mappings["users"].has_key?(_id) && User.exists?(mappings["users"][_id])

    user = User.find_by_email(attributes["email"])

    unless user
      user = User.new do |u|
        attributes.each { |k, v| u[k] = v }
        u.active_instance = Instance.find(mappings["instances"][meta["_active_instance_id"]])
      end
      user.save!(validate: false)
    end

    mappings["users"][_id] = user.id

    return user
  end

  def handle_student_object(obj)
    attributes, meta = partition_object(obj)
    _id              = meta["_id"]

    return if mappings["students"].has_key?(_id) && Student.exists?(mappings["students"][_id])

    student = Student.where(personal_id: attributes["personal_id"]).first

    unless student
      student = Student.new do |s|
        attributes.each { |k, v| s[k] = v }
        s.instance = Instance.find(mappings["instances"][meta["_instance_id"]])
      end
      student.save!
    end

    mappings["students"][_id] = student.id

    return student
  end

  def handle_group_object(obj)
    attributes, meta = partition_object(obj)
    _id              = meta["_id"]

    return if mappings["groups"].has_key?(_id) && Group.exists?(mappings["groups"][_id])

    group = Group.new do |g|
      attributes.each { |k, v| g[k] = v }
      g.instance = Instance.find(mappings["instances"][meta["_instance_id"]])
    end
    group.save!

    collect_mapped_objects(meta["_users"], mappings["users"], User) do |user|
      group.users << user
    end

    collect_mapped_objects(meta["_students"], mappings["students"], Student) do |student|
      group.students << student
    end

    mappings["groups"][_id] = group.id

    return group
  end

  def handle_group_object_for_hierarchy(obj)
    _, meta    = partition_object(obj)
    _id        = meta["_id"]
    _parent_id = meta["_parent_id"]

    group_id   = mappings["groups"][_id]
    parent_id  = mappings["groups"][_parent_id]

    return if group_id.blank? || parent_id.blank?

    group  = Group.where(id: group_id).first
    parent = Group.where(id: parent_id).first

    if group && parent && group.parent.nil?
      group.parent = parent
      group.save!
    end

    return group
  end

  def handle_instruction_object(obj)
    attributes, meta = partition_object(obj)
    _id              = meta["_id"]

    return if mappings["instructions"].has_key?(_id) && Instruction.exists?(mappings["instructions"][_id])

    instruction = Instruction.where(for_page: attributes["for_page"]).first

    unless instruction
      instruction = Instruction.new do |i|
        attributes.each { |k, v| i[k] = v }
      end
      instruction.save!
    end

    mappings["instructions"][_id] = instruction.id

    return instruction
  end

  def handle_suite_object(obj)
    attributes, meta = partition_object(obj)
    _id              = meta["_id"]

    return if mappings["suites"].has_key?(_id) && Suite.exists?(mappings["suites"][_id])

    suite = Suite.new do |s|
      attributes.each { |k, v| s[k] = v }
      s.instance = Instance.find(mappings["instances"][meta["_instance_id"]])
    end
    suite.save!

    mappings["suites"][_id] = suite.id

    return suite
  end

  def handle_suite_object_for_hierarchy(obj)
    _, meta      = partition_object(obj)
    _id          = meta["_id"]
    _template_id = meta["_template_id"]

    suite_id     = mappings["suites"][_id]
    template_id  = mappings["suites"][_template_id]

    return if suite_id.blank? || template_id.blank?

    suite    = Suite.where(id: suite_id).first
    template = Suite.where(id: template_id).first

    if suite && template && suite.template.nil?
      suite.template = template
      suite.save!
    end

    return suite
  end

  def handle_participant_object(obj)
    attributes, meta = partition_object(obj)
    _id              = meta["_id"]
    suite_id         = mappings["suites"][meta["_suite_id"]]
    student_id       = mappings["students"][meta["_student_id"]]
    group_id         = mappings["groups"][meta["_group_id"]]

    return if mappings["participants"].has_key?(_id) &&
      Participant.exists?(mappings["participants"][_id]) ||
      !Suite.exists?(suite_id) ||
      !Student.exists?(student_id) ||
      group_id && !Group.exists?(group_id)

    participant = Participant.where(suite_id: suite_id, student_id: student_id).first

    unless participant
      participant = Participant.new do |p|
        attributes.each { |k, v| p[k] = v }
        p.suite   = Suite.find(suite_id)
        p.student = Student.find(student_id)
        p.group   = Group.find(group_id)     if !group_id.blank?
      end
      participant.save!
    end

    mappings["participants"][_id] = participant.id

    return participant
  end

  def handle_meeting_object(obj)
    attributes, meta = partition_object(obj)
    _id              = meta["_id"]
    suite_id         = mappings["suites"][meta["_suite_id"]]

    return if mappings["meetings"].has_key?(_id) &&
      Meeting.exists?(mappings["meetings"][_id]) ||
      !Suite.exists?(suite_id)

    meeting = Meeting.new do |m|
      attributes.each { |k, v| m[k] = v }
      m.suite = Suite.find(suite_id)
    end
    meeting.save!

    mappings["meetings"][_id] = meeting.id

    return meeting
  end

  def handle_activity_object(obj)
    attributes, meta = partition_object(obj)
    _id              = meta["_id"]
    suite_id         = mappings["suites"][meta["_suite_id"]]
    meeting_id       = mappings["meetings"][meta["_meeting_id"]]

    return if mappings["activities"].has_key?(_id) &&
      Activity.exists?(mappings["activities"][_id]) ||
      !Suite.exists?(suite_id) ||
      meeting_id && !Meeting.exists?(meeting_id)

    activity = Activity.new do |a|
      attributes.each { |k, v| a[k] = v }
      a.suite   = Suite.find(suite_id)
      a.meeting = Meeting.find(meeting_id) if meeting_id
    end
    activity.save!

    mappings["activities"][_id] = activity.id

    return activity
  end

  def handle_generic_evaluation_object(obj)
    return handle_common_evaluation_object(obj, "generic_evaluations")
  end

  def handle_evaluation_template_object(obj)
    return handle_common_evaluation_object(obj, "evaluation_templates")
  end

  def handle_evaluation_template_object_for_hierarchy(obj)
    _, meta       = partition_object(obj)
    _id           = meta["_id"]
    _template_id  = meta["_template_id"]

    evaluation_id = mappings["evaluation_templates"][_id]
    template_id   = mappings["evaluation_templates"][_template_id]

    return if evaluation_id.blank? || template_id.blank?

    evaluation = Evaluation.where(id: evaluation_id).first
    template   = Evaluation.where(id: template_id).first

    if evaluation && template && evaluation.template.nil?
      evaluation.template = template
      evaluation.save!
    end

    return evaluation
  end

  def handle_suite_evaluation_object(obj)
    attributes, meta = partition_object(obj)
    _id              = meta["_id"]
    _template_id     = meta["_template_id"]
    template_id      = mappings["evaluation_templates"][_template_id]

    return if mappings["suite_evaluations"].has_key?(_id) && Evaluation.exists?(mappings["suite_evaluations"][_id])

    evaluation = Evaluation.new do |e|
      attributes.each { |k, v| e[k] = v }
      e.suite    = Suite.find(mappings["suites"][meta["_suite_id"]])
      e.template = Evaluation.find(template_id) if !template_id.blank? && Evaluation.exists?(template_id)
    end
    evaluation.save!

    mappings["suite_evaluations"][_id] = evaluation.id

    return evaluation
  end

  def handle_result_object(obj)
    attributes, meta = partition_object(obj)
    _id              = meta["_id"]
    evaluation_id    = mappings["suite_evaluations"][meta["_evaluation_id"]]
    student_id       = mappings["students"][meta["_student_id"]]

    return if mappings["results"].has_key?(_id) && Result.exists?(mappings["results"][_id]) ||
      !Evaluation.exists?(evaluation_id) ||
      !Student.exists?(student_id)

    result = Result.where(evaluation_id: evaluation_id, student_id: student_id).first

    if result
      # Ensure proper date parsing
      temp = Result.new
      temp.created_at = attributes["created_at"]

      if result.created_at < temp.created_at
        result.value = attributes["value"]
        result.save!
      end
    else
      result = Result.new do |r|
        attributes.each { |k, v| r[k] = v }
        r.evaluation = Evaluation.find(evaluation_id)
        r.student    = Student.find(student_id)
      end
      result.save!
    end

    mappings["results"][_id] = result.id


    return result
  end

  def handle_setting_object(obj)
    attributes, meta     = partition_object(obj)
    _id                  = meta["_id"]
    customizer_mapping   = attributes["customizer_type"].tableize
    customizer_class     = attributes["customizer_type"].constantize
    customizer_id        = mappings[customizer_mapping][meta["_customizer_id"]]
    customizable_mapping = attributes["customizable_type"].tableize
    customizable_class   = attributes["customizable_type"].constantize
    customizable_id      = mappings[customizable_mapping][meta["_customizable_id"]]

    return if mappings["settings"].has_key?(_id) && Setting.exists?(mappings["settings"][_id]) ||
      !customizer_class.exists?(customizer_id) ||
      !customizable_class.exists?(customizable_id)

    setting = Setting.new do |s|
      attributes.each { |k, v| s[k] = v }
      s.customizer   = customizer_class.find(customizer_id)
      s.customizable = customizable_class.find(customizable_id)
    end
    setting.save!

    mappings["settings"][_id] = setting.id

    return setting
  end

  def handle_table_state_object(obj)
    attributes, meta = partition_object(obj)
    _id              = meta["_id"]
    base_mapping     = attributes["base_type"].tableize
    base_class       = attributes["base_type"].constantize
    base_id          = mappings[base_mapping][meta["_base_id"]]

    return if mappings["table_states"].has_key?(_id) && TableState.exists?(mappings["table_states"][_id]) ||
      !base_class.exists?(base_id)

    table_state = TableState.new do |t|
      attributes.each { |k, v| t[k] = v }
      t.base = base_class.find(base_id)
    end
    table_state.save!

    mappings["table_states"][_id] = table_state.id

    return table_state
  end

  def handle_role_object(obj)
    attributes, meta = partition_object(obj)
    name             = attributes["name"]
    resource_type    = attributes["resource_type"]

    if resource_type
      resource_class = resource_type.constantize
      resource_id    = mappings[resource_type.tableize][meta["_resource_id"]]

      return if resource_id && !resource_class.exists?(resource_id)
    else
      resource_id    = nil
      resource_class = nil
    end

    _users = meta["_users"]
    users  = []

    _users.each do |_u|
      user_id = mappings["users"][_u]
      next if !user_id || !User.exists?(user_id)

      user = User.find(user_id)

      if resource_id
        user.add_role name, resource_class.find(resource_id)
      elsif resource_class
        user.add_role name, resource_class
      else
        user.add_role name
      end

      users << user
    end

    return users
  end


  private

  def handle_common_evaluation_object(obj, mapping_key)
    attributes, meta = partition_object(obj)
    _id              = meta["_id"]

    return if mappings[mapping_key].has_key?(_id) && Evaluation.exists?(mappings[mapping_key][_id])

    evaluation = Evaluation.new do |e|
      attributes.each { |k, v| e[k] = v }
      e.instance = Instance.find(mappings["instances"][meta["_instance_id"]])
    end
    evaluation.save!

    mappings[mapping_key][_id] = evaluation.id

    return evaluation
  end


  # Splits an object hash into two, one with
  # keys starting with "_", the other with keys without
  #
  # This exists to separate the regular attributes from the
  # special ones in the export format
  def partition_object(obj)
    obj.stringify_keys.partition { |k,v| k !~ /^_/ }.collect { |h| Hash[h] }
  end

  # Given a list of prefixed export id:s, yield each real
  # object to the block, if it exists
  def collect_mapped_objects(_ids, mapping, klass)
    if _ids
      _ids.each do |_id|
        obj = klass.where(id: mapping[_id]).first
        yield obj if obj
      end
    end
  end
end
