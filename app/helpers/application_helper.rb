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

  # Bootstrap "active" class generator
  def active_if(condition)
    condition ? "active" : ""
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

  # Renders a form for confirming a destroy action
  def confirm_destroy_form(entity, message, options = {})
    cancel_path = url_for(options[:cancel_to] || url_for(entity))

    render partial: "shared/confirm_destroy_form",
      locals: { entity: entity, message: message, cancel_path: cancel_path }
  end
end
