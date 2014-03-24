module VersionHelper
  def listify(list, options = {})
    return ""         if list.blank?
    return list.first if list.length == 1

    content_tag(
      :ul,
      list.collect { |s| content_tag(:li, s) }.join("").html_safe,
      options
    )
  end

  def version_item_link(version)
    if version.item
      if version.item.is_a?(Participant)
        return link_to(version.item.student.try(:name), version.item.student)
      else
        return link_to(version.item.name, version.item)
      end
    else
      version.reload unless version.attributes.has_key?("object")

      if version.object
        object = PaperTrail.serializer.load(version.object) if version.object

        if object.has_key?("name")
          return object["name"]
        elsif object.has_key?("student_id")
          student = Student.where(id: object["student_id"]).first

          if student
            return link_to(student.name, student)
          else
            return "Borttagen elev"
          end
        end
      elsif changes = version.changeset["student_id"]
          student = Student.where(id: changes.last).first

          if student
            return link_to(student.name, student)
          else
            return "Borttagen elev"
          end
      end
    end

    return ""
  end

  def version_events(version)
    case version.item_type
    when "Suite"       then version_events_for_suite(version)
    when "Evaluation"  then version_events_for_evaluation(version)
    when "Meeting"     then version_events_for_meeting(version)
    when "Activity"    then version_events_for_activity(version)
    when "Participant" then version_events_for_participant(version)
    else
      ""
    end
  end

  def version_events_for_suite(version)
    case version.event
    when "create"
      [ t(:"events.suite.created") ]
    when "update"
      suite_changes(version)
    else
      nil
    end
  end

  def version_events_for_evaluation(version)
    case version.event
    when "create"
      [ t(:"events.evaluation.created", name: version.item.name) ]
    when "update"
      evaluation_changes(version)
    else
      nil
    end
  end

  def version_events_for_meeting(version)
    case version.event
    when "create"
      [ t(:"events.meeting.created") ]
    when "update"
      meeting_changes(version)
    else
      nil
    end
  end

  def version_events_for_activity(version)
    case version.event
    when "create"
      [ t(:"events.activity.created") ]
    when "update"
      activity_changes(version)
    else
      nil
    end
  end

  def version_events_for_participant(version)
    case version.event
    when "create"
      [ t(:"events.participant.created") ]
    when "destroy"
      [ t(:"events.participant.destroyed") ]
    end
  end


  private

  def suite_changes(version)
    changes = []

    version.changeset.each do |attribute, change|
      case attribute
      when "name"
        changes << t(:"events.suite.name_changed", from: change.first, to: change.second)
      end
    end

    return changes
  end

  def evaluation_changes(version)
    changes = []

    version.changeset.each do |attribute, change|
      case attribute
      when "name"
        changes << t(:"events.evaluation.name_changed",        from: change.first, to: change.second)
      when "max_result"
        changes << t(:"events.evaluation.max_result_changed",  from: change.first, to: change.second)
      when "date"
        changes << t(:"events.evaluation.date_changed",        from: change.first, to: change.second)
      when "description"
        changes << t(:"events.evaluation.description_changed", from: change.first, to: change.second)
      when "target"
        changes << t(
          :"events.evaluation.target_changed",
          from: t(:"enumerize.evaluation.target.#{change.first}"),
          to: t(:"enumerize.evaluation.target.#{change.second}")
        )
      when "colors"
        changes << t(:"events.evaluation.colors_changed")
      when "stanines"
        changes << t(:"events.evaluation.stanines_changed")
      when "status"
        changes << t(:"events.evaluation.status_#{change.second}")
      end
    end

    return changes
  end

  def meeting_changes(version)
    changes = []

    version.changeset.each do |attribute, change|
      case attribute
      when "name"
        changes << t(:"events.meeting.name_changed", from: change.first, to: change.second)
      when "date"
        changes << t(:"events.meeting.date_changed", from: change.first, to: change.second)
      when "completed"
        changes << t(:"events.meeting.#{change.second ? "" : "un"}completed")
      end
    end

    return changes
  end

  def activity_changes(version)
    changes = []

    version.changeset.each do |attribute, change|
      case attribute
      when "name"
        changes << t(:"events.activity.name_changed",       from: change.first, to: change.second)
      when "start_date"
        changes << t(:"events.activity.start_date_changed", from: change.first, to: change.second)
      when "end_date"
        changes << t(:"events.activity.end_date_changed",   from: change.first, to: change.second)
      when "status"
        changes << t(:"events.activity.#{change.second}")
      end
    end

    return changes
  end
end
