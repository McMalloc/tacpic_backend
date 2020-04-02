Tacpic.hash_branch "users" do |r|
  # @request = JSON.parse r.body.read

  # r.on Integer do |user_id|
  r.get 'validate' do
    {
        display_name: User[rodauth.logged_in?][:display_name],
        id: rodauth.logged_in?
    }
  end

  r.get Integer do

  end

  # GET users/versions
  # Gets all versions that the currently logged in user created. The result can be used to deduce the corresponding graphics and variants.
  r.on 'versions' do
    rodauth.require_authentication
    user_id = rodauth.logged_in?

    r.is do

      where_clause = {
          user_id: user_id
      }

      selection_clause = [
          Sequel[:versions][:id].as(:id),
          Sequel[:graphics][:title].as(:graphic_title),
          Sequel[:variants][:title].as(:variant_title),
          Sequel[:graphics][:id].as(:graphic_id),
          Sequel[:variants][:id].as(:variant_id),
          Sequel[:variants][:description].as(:variant_description),
          Sequel[:graphics][:description].as(:graphic_description),
          Sequel[:variants][:created_at].as(:created_at),
          Sequel[:versions][:created_at].as(:updated_at)
      ]

      order_clause = Sequel.desc(:created_at)

      unless r.params['tags'].nil?
        tag_ids = r.params['tags'].split(',').map(&:to_i)

        where_clause[:variant_id] = Variant
                                        .select(
                                            Sequel[:variants][:id],
                                            Sequel[:taggings][:id].as(:tagging_id),
                                            Sequel[:taggings][:tag_id]
                                        )
                                        .join(:taggings, variant_id: :id)
                                        .where(tag_id: tag_ids)
                                        .all.map { |v| v[:id] }
      end

      unless r.params['search'].nil?
        term = r.params['search']
        match_string = %Q{
          variants.title LIKE '%#{term}%' OR
          variants.description LIKE '%#{term}%' OR
          graphics.title LIKE '%#{term}%' OR
          graphics.description LIKE '%#{term}%'
        }
        # selection_clause.push Sequel.lit(match_string + " AS score")
        # order_clause = Sequel.desc(:score)

        Version
            .select(*selection_clause)
            .join(:variants, id: :variant_id)
            .join(:graphics, id: :graphic_id)
            .order(order_clause)
            .where(Sequel.lit(match_string))
            .where(where_clause)
            .all.map(&:values)
      else
        Version
            .select(*selection_clause)
            .join(:variants, id: :variant_id)
            .join(:graphics, id: :graphic_id)
            .order(order_clause)
            .where(where_clause)
            .all.map(&:values)
      end


    end

  end
end