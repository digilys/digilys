require "yajl"

class Digilys::Importer
  def initialize(id_prefix)
    @id_prefix = id_prefix
    @parser = Yajl::Parser.new
  end
end
