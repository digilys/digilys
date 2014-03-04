module PaperTrail
  class Version < ActiveRecord::Base
    # Metadata for PaperTrail
    attr_accessible :suite_id
  end
end

PaperTrail.serializer = PaperTrail::Serializers::JSON
