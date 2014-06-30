module GroupsHelper
  def render_group_tree(groups, status = :open)
    #require 'pry'; binding.pry
    return "" if groups.blank?

    html = ""

    groups.each do |group|
      html << render(partial: "group_row", locals: { group: group })
      html << render_group_tree(group.children.with_status(status))
    end

    return html.html_safe
  end


  # Return group status based on action. It return :open unless
  # the action is groups/closed.
  def status_from_action
    if params[:action].try(:to_sym) == :closed
      :closed
    else
      :open
    end
  end
end
