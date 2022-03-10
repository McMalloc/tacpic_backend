Tacpic.hash_branch 'users' do |r|
  # @request = JSON.parse r.body.read

  r.on 'addresses' do
    r.post Integer do |id|
      rodauth.require_authentication
      unless Address[id].user_id == rodauth.logged_in? || User[user_id].user_rights.can_view_admin
        response.status = CONSTANTS::HTTP::FORBIDDEN
        return 'unauthorized to update address'
      end
      r.params.delete 'id'
      Address[id].update(r.params)
      response.status = CONSTANTS::HTTP::OK
      Address[id]
    end

    r.post 'inactivate', Integer do |id|
      rodauth.require_authentication
      begin
        address = Address[id]
        if address.nil?
          response.status = CONSTANTS::HTTP::NOT_FOUND
          'Error: Ressource address does not exist'
        elsif address.user_id == rodauth.logged_in?
          address.update active: false
          response.status = CONSTANTS::HTTP::NO_CONTENT
          nil
        else
          response.status = CONSTANTS::HTTP::FORBIDDEN
          'Error: User ID of address to delete does not match authenticated user ID.'
        end
      rescue StandardError
        response.status = CONSTANTS::HTTP::INTERNAL
        $!.to_json
      end
    end

    r.is do
      r.get do
        begin
          rodauth.require_authentication
          Address.where(user_id: rodauth.logged_in?, active: true).map(&:values)
        rescue Sequel::Error
          response.status = CONSTANTS::HTTP::UNAUTHORIZED
          $!.to_json
        end
      end
      r.post do
        rodauth.require_authentication
        begin
          # if request[:last_name].nil? && request[:company_name].nil?
          #   response.status = 400
          #   raise "at least one name needs to be present"
          # else
          r.params.delete 'id'
          r.params['country'] = 'DEU'
          values = User[rodauth.logged_in?].add_address(r.params).values
          response.status = CONSTANTS::HTTP::CREATED
          return values
        # end
        rescue Sequel::Error
          response.status = CONSTANTS::HTTP::UNAUTHORIZED
          pp $!
        end
      end
    end
  end

  # r.on Integer do |user_id|
  r.get 'validate' do
    rodauth.require_authentication
    user_id = rodauth.logged_in?
    response = User[user_id].values.dup
    response[:user_rights] = UserRights.find(user_id: user_id).values unless UserRights.find(user_id: user_id).nil?
    return response
  end

  r.post do
    rodauth.require_authentication
    user_id = rodauth.logged_in?

    User[user_id].update(display_name: request['displayName'], newsletter_active: request['newsletterActive'])
    User[user_id].values
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

      if r.params['search'].nil?
        Version
          .select(*selection_clause)
          .join(:variants, id: :variant_id)
          .join(:graphics, id: :graphic_id)
          .order(order_clause)
          .where(where_clause)
          .all.map(&:values)
      else
        term = r.params['search']
        match_string = %(
          variants.title LIKE '%#{term}%' OR
          variants.description LIKE '%#{term}%' OR
          graphics.title LIKE '%#{term}%' OR
          graphics.description LIKE '%#{term}%'
        )
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
      end
    end
  end
end
