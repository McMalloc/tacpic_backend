class Tacpic < Roda
  route do |r|
    r.on "tags" do

      # GET /tags
      # Get tags in order of popularity, e.g. number of taggings.
      # @parameter term [String] Look for tags like the provided term. DOes not order by popularity / tagging count.
      # @return tag_id [Integer] ID of the tag
      # @return name [String] Original name of the tag.
      # @return count [Integer] Quantity of taggings for the tag (not if term is provided).
      r.get Integer do |id|
        Tagging[id].values
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
    end
  end
end

