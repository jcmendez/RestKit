class CreateHumans < ActiveRecord::Migration
  def self.up
    create_table :humans, :force => true do |t|
      t.string :name
      t.integer :age
      t.date :birthday
      t.string :sex
      t.timestamps
    end
  end

  def self.down
    drop_table :humans
  end
end