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


  private

  # Splits an object hash into two, one with
  # keys starting with "_", the other with keys without
  #
  # This exists to separate the regular attributes from the
  # special ones in the export format
  def partition_object(obj)
    obj.stringify_keys.partition { |k,v| k !~ /^_/ }.collect { |h| Hash[h] }
  end
end
