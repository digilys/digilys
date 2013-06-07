class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :authenticate_user!

  check_authorization unless: :skip_authorization?

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from CanCan::AccessDenied,         with: :access_denied

  protected

  # When creating participants, two autocompletes are used, one for selecting
  # students, one for groups. The autocomplete generates two parameters, :student_id
  # and :group_id, which are comma separated list of the selected ids.
  #
  # The comma separated list of ids need to be converted to proper parameters for
  # creating distinct participants, which means the following parameters:
  #
  #  {
  #    group_id: group_id, # if any
  #    student_id: student_id
  #  }
  #
  # This method converts the following structure:
  #
  #  {
  #    group_id: "1,2",
  #    student_id: "10, 11"
  #  }
  #
  # to the following structure:
  #
  #  [ {
  #    group_id: 1,
  #    student_id: 20 # student 20 is a member of group 1
  #  }, {
  #    group_id: 2,
  #    student_id: 10 # student 10 is a member of group 1, thus the inclusino from student_id above is overridden
  #  }, {
  #    group_id: nil,
  #    student_id: 11 # from student_id above
  #  } ]
  #
  # Also, see the specs for this method for its behaviour
  def process_participant_autocomplete_params(data)
    return nil if data.blank?

    result = {}

    if data[:student_id]
      data[:student_id].split(",").each do |student_id|
        student_id = student_id.to_i
        result[student_id] = { student_id: student_id }
      end
    end

    if data[:group_id]
      group_ids = data[:group_id].split(",")

      unless group_ids.blank?
        Group.where(:id => group_ids).each do |group|
          group.student_ids.each do |student_id|
            result[student_id] = {
              group_id: group.id,
              student_id: student_id
            }
          end
        end
      end
    end

    return result.values
  end


  private

  # This picks up any layout set in the inheriting controller
  def record_not_found
    render template: "shared/404", status: 404
  end
  # This picks up any layout set in the inheriting controller
  def access_denied
    render template: "shared/401", status: 401
  end

  def skip_authorization?
    devise_controller? || self.is_a?(RailsAdmin::ApplicationController)
  end
end
