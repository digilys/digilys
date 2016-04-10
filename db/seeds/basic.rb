## Development base scenario
#
# Run app:factory:students first
#
# 3 users:
# - 1 planner
# - 1 reader (regular user)
# - 1 editor (regular user)
#
# 1 evaluation template
#
# 2 generic evaluations, booleans
#
# 1 group, adds the first 5 students to the group
#
# Data added to the first student:
# - Student data, a few different keys and values
# - Results for the two generic evaluations

instance = Instance.order("id asc").first

puts "planner"
user = User.new do |u|
  u.name                  = "planner"
  u.email                 = "planner@example.com"
  u.password              = "testtest"
  u.password_confirmation = "testtest"
  u.active_instance       = instance
end

user.save!
user.add_role :planner

puts "Reader"
user = User.new do |u|
  u.name                  = "Reader"
  u.email                 = "reader@example.com"
  u.password              = "testtest"
  u.password_confirmation = "testtest"
  u.active_instance       = instance
end

user.save!

puts "Editor"
user = User.new do |u|
  u.name                  = "Editor"
  u.email                 = "editor@example.com"
  u.password              = "testtest"
  u.password_confirmation = "testtest"
  u.active_instance       = instance
end

user.save!

puts "Evaluation template"
Evaluation.create!({
  instance:      instance,
  type:          "template",
  name:          "Test template",
  description:   "",
  target:        "all",
  category_list: "",
  max_result:    "8",
  yellow_min:    "3",
  yellow_max:    "5",
  red_min:       "0",
  red_max:       "2",
  green_min:     "6",
  green_max:     "8",
  stanine1_min:  "0",
  stanine1_max:  "0",
  stanine2_min:  "1",
  stanine2_max:  "1",
  stanine3_min:  "2",
  stanine3_max:  "2",
  stanine4_min:  "3",
  stanine4_max:  "3",
  stanine5_min:  "4",
  stanine5_max:  "4",
  stanine6_min:  "5",
  stanine6_max:  "5",
  stanine7_min:  "6",
  stanine7_max:  "6",
  stanine8_min:  "7",
  stanine8_max:  "7",
  stanine9_min:  "8",
  stanine9_max:  "8"
})

puts "Generic evaluations"
generic1 = Evaluation.create!({
  instance:        instance,
  type:            "generic",
  name:            "Boolean 1",
  description:     "",
  value_type:      "boolean",
  color_for_true:  "green",
  color_for_false: "red"
})

generic2 = Evaluation.create!({
  instance:        instance,
  type:            "generic",
  name:            "Boolean 2",
  description:     "",
  value_type:      "boolean",
  color_for_true:  "red",
  color_for_false: "green"
})

puts "Group 1"
group = Group.create!({
  instance: instance,
  name:     "Group 1"
})
group.add_students(Student.order("first_name asc, last_name asc").limit(5))

puts "Student data"
student = Student.order("first_name asc, last_name asc").first
student.data_text = "Foo: Bar\nBar: Baz\nApa: Bepa\nBepa: Cepa\nCepa: Depa\nDepa: Epa\nEpa: Fepa"
student.save!

puts "Generic evaluation results"
Result.create!(
  student_id:    student.id,
  evaluation_id: generic1.id,
  value:         "0"
)
Result.create!(
  student_id:    student.id,
  evaluation_id: generic2.id,
  value:         "0"
)
