class CreateProposals < Sequel::Migration
  def up
    create_table :proposals do
      foreign_key :variant_id, :variants
      foreign_key :request_id, :requests

      # primary_key [:variant_id, :request_id], name: :proposal_pk
      DateTime :created_at
    end
  end

  def down
    drop_table? :proposals
  end
end