class AddTradableToInstruments < ActiveRecord::Migration[8.0]
  def change
    add_column :instruments, :tradable, :boolean, default: false # rubocop:disable Rails/ThreeStateBooleanColumn
    add_index :instruments, :tradable
  end
end
