module UsersHelper
  # Administrator can only be edited by admin role
  # FIXME: Why can't this be done using cancan and abilities?
  def manageable?(user)
    !user.is_administrator? || current_user.has_role?(:admin)
  end
end
