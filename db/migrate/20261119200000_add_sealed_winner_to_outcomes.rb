class AddSealedWinnerToOutcomes < ActiveRecord::Migration[8.1]
  def change
    add_column :outcomes, :sealed_winner, :boolean, default: false, null: false
    add_index :outcomes, :market_id, unique: true, where: "sealed_winner", name: "index_outcomes_on_market_id_one_sealed_winner"
  end
end
