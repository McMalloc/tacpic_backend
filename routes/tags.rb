Tacpic.hash_branch 'tags' do |r|

  # GET /tags/:id
  r.get Integer do |id|
    Tag[id].values
  end

  # GET /tags/search/:term
  # Get tags which name is similiar to the provided term (useful for tag suggestions). Does not order by popularity / tagging count.
  # @parameter term [String] Search term.
  # @return Tag TODO wie unveränderte Models dokumentieren?
  r.get "search", String do |term|
    Tag.where(Sequel.ilike(:name, "%#{term}%")).map(&:values)
  end

  # GET /tags
  # Get tags in order of popularity, e.g. number of taggings.
  # @return tag_id [Integer] ID of the tag
  # @return name [String] Original name of the tag.
  # @return count [Integer] Quantity of taggings for the tag.
  r.get do
    rodauth.require_authentication
    user_id = rodauth.logged_in?
    limit = r.params['limit'].nil? ? 10 : r.params['limit'].to_i
    Tagging
        .left_join(:tags, id: :tag_id)
        .group_and_count(:tag_id, :name, :description, :taxonomy_id)
        .limit(limit) #.where(Sequel.lit("taxonomy_id = 1 OR tags.user_id = " + user_id.to_s))
        .order(:count)
        .reverse
        .map(&:values)

    # tags = Tag
    #     .select(
    #         :id,
    #         :taxonomy_id,
    #         :name,
    #         :description
    #     )
    #     .where(id: popular_tags.map(&:tag_id))
    #     # .map(&:values)
    #
    # popular_tags.map {|counted_tag|
    #   tags[counted_tag.tag_id]
    # }
  end

  r.post do
    rodauth.require_authentication
    user_id = rodauth.logged_in?
    name = request[:name].strip.downcase

    if Tag.where(name: name).all.length > 0
      response.status = 409 # Conflict
      response.write "tag already exists" # TODO systematic error messages
      request.halt
    end

    tag = Tag.create(
        name: name,
        # taxonomy: request[:taxonomy_id] || 0, # 0 is default, a taxonomy for content-related tags
        user_id: user_id
    )
    response.status = 201
    tag.values
  end

end

