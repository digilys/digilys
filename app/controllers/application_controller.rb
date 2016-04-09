class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :authenticate_user!

  check_authorization unless: :skip_authorization?

  cache_sweeper :cache_observer

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from CanCan::AccessDenied,         with: :access_denied

  protected

  def current_instance_id
    current_user.active_instance_id
  end
  helper_method :current_instance_id
  def current_instance
    current_user.active_instance
  end
  helper_method :current_instance

  def current_name_order(prefix = nil)
    prefix = "#{prefix}." if prefix

    if current_user.name_ordering == :last_name
      "#{prefix}last_name, #{prefix}first_name"
    else
      "#{prefix}first_name, #{prefix}last_name"
    end
  end
  helper_method :current_name_order

  def has_search_param?(allow_blank = false)
    if params[:q] && !allow_blank
      params[:q] = params[:q].reject { |_, v| v.blank? }
    end

    return !params[:q].blank?
  end
  helper_method :has_search_param?

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

  def authorize_import(type)
    authorize! ("import_" + type).to_sym, Instance
  end

  def authorize_restore
    authorize! :restore, :all
  end

  def timestamp_prefix(s)
    "#{Time.zone.now.to_s(ActiveRecord::Base.cache_timestamp_format)}-#{s}"
  end


  private

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_url()
  end

  # This picks up any layout set in the inheriting controller
  def record_not_found
    render template: "shared/404", status: 404
  end
  # This picks up any layout set in the inheriting controller
  def access_denied
    render template: "shared/401", status: 401
  end

  def skip_authorization?
    devise_controller?
  end
end
