class AddYubikeyFieldsToUser < ActiveRecord::Migration
  def change
    add_column :users, :use_yubikey,        :boolean, default: true
    add_column :users, :registered_yubikey, :string
  end
end
