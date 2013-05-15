module GroupsHelper
  def render_group_tree(groups)
    return "" if groups.blank?

    html = ""

    groups.each do |group|
      html << render(partial: "group_row", locals: { group: group })
      html << render_group_tree(group.children)
    end

    return html.html_safe
  end
end
