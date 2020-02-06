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
    limit = r.params['limit'].nil? ? 10 : r.params['limit'].to_i
    Tagging
        .left_join(:tags, id: :tag_id)
        .group_and_count(:tag_id, :name)
        .order(:count)
        .reverse
        .limit([50, limit].min)
        .map(&:values)
  end

  r.post do
    rodauth.require_authentication
    @request = JSON.parse r.body.read
    user_id = rodauth.logged_in?
    name = @request['name'].strip.downcase

    if Tag.where(name: name).all.length > 0
      response.status = 409 # Conflict
      response.write "tag already exists" # TODO systematic error messages
      request.halt
    end

    @tag = Tag.create(
        name: name,
        taxonomy: @request['taxonomy'] || 0, # 0 is default, a taxonomy for content-related tags
        user_id: user_id
    )
    response.status = 202
    @tag.values
  end

end

