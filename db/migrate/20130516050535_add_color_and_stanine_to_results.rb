class AddColorAndStanineToResults < ActiveRecord::Migration
  def up
    add_column :results, :color,   :string
    add_column :results, :stanine, :integer

    Result.includes(:evaluation).find_each do |result|
      result.save
    end
  end
  def down
    remove_column :results, :color
    remove_column :results, :stanine
  end
end
