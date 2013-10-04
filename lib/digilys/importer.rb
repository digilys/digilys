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


  private

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
