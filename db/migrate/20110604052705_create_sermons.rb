class CreateSermons < ActiveRecord::Migration
  def self.up
    create_table :sermons do |t|
      t.date :published_date
      t.string :title
      t.string :filename
      t.text :content

      t.timestamps
    end
  end

  def self.down
    drop_table :sermons
  end
end
