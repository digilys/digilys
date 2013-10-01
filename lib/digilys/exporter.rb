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

  private

  def id_filter(hash)
    hash.inject({}) do |h, (k,v)|
      if k =~ /^(id|.+_id)$/
        h["_#{k}"] = "#{@id_prefix}-#{v}"
      else
        h[k] = v
      end
      h
    end
  end
end
