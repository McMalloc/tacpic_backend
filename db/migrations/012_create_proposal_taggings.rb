class CreateProposalTaggings < Sequel::Migration
  def up
    create_table :proposal_taggings do
      primary_key :id
      foreign_key :tag_id
      foreign_key :proposal_id
      foreign_key :user_id
      DateTime :created_at
    end
  end

  def down
    drop_table :proposal_taggings
  end
end