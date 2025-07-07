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

      t.timestamps
    end
  end
end
