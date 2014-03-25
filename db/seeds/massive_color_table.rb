## Creates a massive color table
#
# Run app:factory:students before
#
# 1 suite
# 40 evaluations belonging to the suite
# All students become participants in the suite
# Random result for all students in all evaluations

instance = Instance.order("id asc").first

puts "Suite"
suite = Suite.new do |s|
  s.name     = "Massive color table"
  s.instance = instance
end

puts "Evaluations"
evaluations = ((Date.today)..(Date.today + 39.days)).collect do |date|
  print "."
  Evaluation.create!({
    suite:         suite,
    date:          date,
    type:          "suite",
    name:          "Test #{date}",
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
end
puts ""

puts "Participants"
Student.all.each do |student|
  print "."
  Participant.create!({
    student_id: student.id,
    suite_id:   suite.id,
  })
end
puts ""

puts "Results"
evaluations.each do |evaluation|
  Student.all.each do |student|
    print "."
    value = rand(9) - 1

    if value >= 0
      Result.create!({
        student_id:    student.id,
        evaluation_id: evaluation.id,
        value:         value
      })
    else
      Result.create!({
        student_id:    student.id,
        evaluation_id: evaluation.id,
        value:         nil,
        absent:        true
      })
    end
  end
end
puts ""
