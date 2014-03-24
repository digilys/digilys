json.id    @user.id
json.name  @user.name
json.email @user.email
json.row   render partial: "row", locals: { subject: @subject, user: @user }
