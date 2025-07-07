class CreateRecommendations < ActiveRecord::Migration[8.0]
  def change
    create_table :recommendations do |t|
      t.references :instrument, null: false, foreign_key: true
      t.string :strategy
      t.string :style
      t.string :action
      t.decimal :trigger_price, precision: 15, scale: 5
      t.decimal :confidence, precision: 5, scale: 2
      t.datetime :valid_till
      t.jsonb :meta
      t.decimal :entry_price, precision: 10, scale: 2
      t.decimal :stop_loss, precision: 10, scale: 2
      t.decimal :take_profit, precision: 10, scale: 2
      t.integer :quantity
      t.jsonb :pyramid_entries
      t.string :option_strike
      t.decimal :expected_profit_percent, precision: 5, scale: 2

      t.timestamps
    end
  end
end
