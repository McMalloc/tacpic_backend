# first migration's up won't get executed properly, so do nothing instead

class CreateNothing < Sequel::Migration
  def up

  end

  def down

  end
end