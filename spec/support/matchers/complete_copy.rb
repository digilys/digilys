RSpec::Matchers.define :be_a_complete_copy_of do |base|
  # Deep comparison of two objects
  def compare_objects(first, second, prefix = "")
    # Quick return if it's the same object
    return [] if first.id == second.id

    # The object's attributes
    attributes = first.class.attribute_names -
      (@ignore_attributes[first.class] || []).collect(&:to_s) -
      %w(id created_at updated_at)

    diffs = attributes.reject { |attr| first.send(attr) == second.send(attr) }
      .collect { |attr| "#{prefix}#{attr}"}

    # Acts as taggable on
    if first.class.respond_to?(:tag_types)
      first.class.tag_types.each do |context|
        attr = "#{context.to_s.singularize}_list"
        diffs << attr if first.send(attr).sort != second.send(attr).sort
      end
    end

    # Check associated objects, except belongs_to
    associations = [
      first.class.reflect_on_all_associations(:has_one),
      first.class.reflect_on_all_associations(:has_many),
      first.class.reflect_on_all_associations(:has_and_belongs_to_many)
    ].flatten.collect(&:name) - (@ignore_associations[first.class] || []).collect(&:to_sym) - [ :versions ]

    associations.each do |association_name|
      first_assoc  = first.send(association_name)
      second_assoc = second.send(association_name)

      if !first_assoc.blank? && !second_assoc.blank?
        # None are blank
        if first_assoc.is_a?(ActiveRecord::Base)
          # Single object
          diffs += compare_objects(first_assoc, second_assoc, "#{association_name}.")
        else
          # Array of objects
          first_assoc.each_with_index do |obj, i|
            diffs += compare_objects(obj, second_assoc[i], "#{association_name}[#{i}].")
          end
        end
      elsif first_assoc.blank? && !second_assoc.blank? || !first_assoc.blank? && second_assoc.blank?
        # One is empty, but not the other
        diffs << association_name
      end
    end

    return diffs
  end

  match do |actual|
    @diffs = compare_objects(base, actual)
    @diffs.blank?
  end

  failure_message_for_should do |actual|
    "expected #{actual.inspect} to be a complete copy of #{base.inspect}, diffs: #{@diffs.join(", ")}"
  end

  chain :ignore_attributes do |attributes|
    @ignore_attributes = attributes
  end
  chain :ignore_associations do |associations|
    @ignore_associations = associations
  end
end
