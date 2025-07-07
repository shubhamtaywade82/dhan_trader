class CreatePortfolioLots < ActiveRecord::Migration[8.0]
  def change
    create_table :portfolio_lots do |t|
      t.integer :user_id
      t.references :instrument, null: false, foreign_key: true
      t.integer :qty
      t.decimal :avg_price, precision: 15, scale: 5

      t.timestamps
    end
  end
end
