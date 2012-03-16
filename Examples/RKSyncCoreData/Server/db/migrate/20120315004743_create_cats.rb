class CreateCats < ActiveRecord::Migration
  def self.up
    create_table :cats, :force => true do |t|
      t.references :owner
      t.string :name
      t.string :nickname
      t.integer :age
      t.integer :birth_year
      t.string :sex
      t.timestamps
    end
  end

  def self.down
    drop_table :cats
  end
end