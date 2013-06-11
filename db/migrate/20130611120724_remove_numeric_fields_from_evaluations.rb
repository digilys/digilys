class RemoveNumericFieldsFromEvaluations < ActiveRecord::Migration
  def up
    Evaluation.where(value_type: "numeric").find_each do |evaluation|
      red_below   = evaluation.send(:read_attribute, :red_below)
      green_above = evaluation.send(:read_attribute, :green_above)

      colors = {}
      colors["red"]    = { min: 0,               max: red_below - 1 }         if red_below > 0
      colors["yellow"] = { min: red_below,       max: green_above }
      colors["green"]  = { min: green_above + 1, max: evaluation.max_result } if green_above < evaluation.max_result

      evaluation.update_column(:colors, colors.to_json)

      stanine1 = evaluation.send(:read_attribute, :stanine1)

      if stanine1
        stanine2 = evaluation.send(:read_attribute, :stanine2)
        stanine3 = evaluation.send(:read_attribute, :stanine3)
        stanine4 = evaluation.send(:read_attribute, :stanine4)
        stanine5 = evaluation.send(:read_attribute, :stanine5)
        stanine6 = evaluation.send(:read_attribute, :stanine6)
        stanine7 = evaluation.send(:read_attribute, :stanine7)
        stanine8 = evaluation.send(:read_attribute, :stanine8)

        stanines = {}

        stanines[1] = { min: 0, max: stanine1 }
        stanines[2] = { min: stanine1 + 1, max: stanine2 }              if stanine2 > stanine1
        stanines[3] = { min: stanine2 + 1, max: stanine3 }              if stanine3 > stanine2
        stanines[4] = { min: stanine3 + 1, max: stanine4 }              if stanine4 > stanine3
        stanines[5] = { min: stanine4 + 1, max: stanine5 }              if stanine5 > stanine4
        stanines[6] = { min: stanine5 + 1, max: stanine6 }              if stanine6 > stanine5
        stanines[7] = { min: stanine6 + 1, max: stanine7 }              if stanine7 > stanine6
        stanines[8] = { min: stanine7 + 1, max: stanine8 }              if stanine8 > stanine7
        stanines[9] = { min: stanine8 + 1, max: evaluation.max_result } if evaluation.max_result > stanine8

        evaluation.update_column(:stanines, stanines.to_json)
      end
    end

    remove_column :evaluations, :red_below
    remove_column :evaluations, :green_above
    remove_column :evaluations, :stanine1
    remove_column :evaluations, :stanine2
    remove_column :evaluations, :stanine3
    remove_column :evaluations, :stanine4
    remove_column :evaluations, :stanine5
    remove_column :evaluations, :stanine6
    remove_column :evaluations, :stanine7
    remove_column :evaluations, :stanine8
  end

  def down
    add_column :evaluations, :red_below,   :integer
    add_column :evaluations, :green_above, :integer
    add_column :evaluations, :stanine1,    :integer
    add_column :evaluations, :stanine2,    :integer
    add_column :evaluations, :stanine3,    :integer
    add_column :evaluations, :stanine4,    :integer
    add_column :evaluations, :stanine5,    :integer
    add_column :evaluations, :stanine6,    :integer
    add_column :evaluations, :stanine7,    :integer
    add_column :evaluations, :stanine8,    :integer

    Evaluation.reset_column_information
    Evaluation.inheritance_column = :disable_inheritance

    Evaluation.where(value_type: "numeric").find_each do |evaluation|
      colors = evaluation.colors

      if !colors.blank?
        evaluation.update_column(:red_below,   colors["yellow"]["min"])
        evaluation.update_column(:green_above, colors["yellow"]["max"])
      end

      stanines = evaluation.stanines

      if !stanines.blank?
        evaluation.update_column(:stanine1, upper_limit_for_stanine(stanines, 1))
        evaluation.update_column(:stanine2, upper_limit_for_stanine(stanines, 2))
        evaluation.update_column(:stanine3, upper_limit_for_stanine(stanines, 3))
        evaluation.update_column(:stanine4, upper_limit_for_stanine(stanines, 4))
        evaluation.update_column(:stanine5, upper_limit_for_stanine(stanines, 5))
        evaluation.update_column(:stanine6, upper_limit_for_stanine(stanines, 6))
        evaluation.update_column(:stanine7, upper_limit_for_stanine(stanines, 7))
        evaluation.update_column(:stanine8, upper_limit_for_stanine(stanines, 8))
      end
    end
  end

  def upper_limit_for_stanine(stanines, stanine)
    if stanines
      stanine.downto(1) do |i|
        return stanines[i.to_s]["max"].to_i if stanines[i.to_s]
      end
    end
    return nil
  end
end
