class CreateQueries < ActiveRecord::Migration
  def self.up
    create_table :queries do |t|
      t.string :query
      t.integer :count
      t.datetime :last_use

      t.timestamps
    end
  end

  def self.down
    drop_table :queries
  end
end
