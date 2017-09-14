module ApplicationHelper
  ALERT_TYPES = [:error, :info, :success, :warning]

  def bootstrap_flash
    flash_messages = []
    flash.each do |type, message|
      # Skip empty messages, e.g. for devise messages set to nothing in a locale file.
      next if message.blank?

      type = :success if type == :notice
      type = :error   if type == :alert
      next unless ALERT_TYPES.include?(type)

      Array(message).each do |msg|
        text = content_tag(
          :div,
          content_tag(
            :button,
            raw("&times;"),
            class: "close",
            "data-dismiss" => "alert"
          ) + msg.html_safe,
            class: "alert fade in alert-#{type}"
        )
        flash_messages << text if message
      end
    end
    flash_messages.join("\n").html_safe
  end

  def instance_indicator
    render partial: "shared/instance_indicator"
  end

  # Duplicate from application_controller to allow (user/new) view testing
  def current_instance
    current_user.active_instance
  end

  def templates_menu
    render partial: "shared/templates_menu"
  end

  def import_menu
    render partial: "shared/import_menu"
  end

  def students_menu
    render partial: "shared/students_menu"
  end

  # Bootstrap "active" class generator
  def active_if(condition)
    condition ? "active" : ""
  end

  # Display the eula
  def show_eula?
    if user_signed_in? && !user_session[:has_shown_eula]
      user_session[:has_shown_eula] = true
      return true
    else
      return false
    end
  end

  # Checks if all the keys and values in any of +parameters+
  # match the current params
  def params?(*parameters)
    param_array = params.to_a

    # http://stackoverflow.com/a/7585278
    parameters.each do |ps|
      return true if (ps.stringify_keys.to_a - param_array).empty?
    end

    return false
  end

  def menu
    render partial: "shared/menu", locals: { suite: @suite, evaluation: @evaluation }
  end

  # Checks if the user is under the import namespace
  def working_with_import?
    params[:controller].start_with?("import/")
  end

  def working_with_trash?
    params[:controller].start_with?("trash")
  end

  # Renders a form for confirming a destroy action
  def confirm_destroy_form(entity, message, options = {})
    cancel_path = url_for(options[:cancel_to] || url_for(entity))

    render partial: "shared/confirm_destroy_form",
      locals: { entity: entity, message: message, cancel_path: cancel_path, options: options }
  end

  def simple_search_form(field)
    render partial: "shared/simple_search_form",
      locals: { field: field.to_s }
  end


  ## Google visualization

  # Initializes Google visualization libraries
  def gchart_init
    html =  javascript_include_tag("//www.google.com/jsapi")
    html << javascript_tag(%(google.load("visualization", "1.0", {"packages": ["corechart"]});))
    content_for :page_end, html
  end

  # Code for generating a Google chart
  def gchart(options)
    id   = options.delete(:id)
    url  = options.delete(:url)
    type = options.delete(:type)

    error_message = content_tag(
      :div,
      content_tag(
        :button,
        raw("&times;"),
        class: "close",
        "data-dismiss" => "alert"
      ) + t(:gchart_error),
        class: "alert fade in alert-error"
    )

    html = javascript_tag(%(
      ;(function(google, $) {
        google.setOnLoadCallback(function() {
          var chart = new google.visualization.#{type.to_s.capitalize}Chart(document.getElementById("#{id}"));

          google.visualization.events.addListener(chart, 'error', function(error) {
            $(document.getElementById(error.id)).parent().remove();
            #{"console.log(error);" if Rails.env.development?}
            $("##{id}").prepend('#{error_message}');
          });

          $.getJSON("#{url}", function(data) {
            chart.draw(google.visualization.arrayToDataTable(data), #{options.to_json});
          });
        });
      })(google, jQuery);
    ))
    content_for :page_end, html
  end


  ## TinyMCE
  def tinymce_autofocus(id)
    javascript_tag(%(
      tinyMCE.on("AddEditor", function(e) {
        if (e.editor.id == '#{id}') {
          e.editor.on("init", function(ev) {
            try {
              tinyMCE.execCommand("mceFocus", false, ev.target.id);
            } catch(err) { }
          });
        }
      });
    ))
  end
end
