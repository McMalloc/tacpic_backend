Tacpic.hash_branch "variants" do |r|

  r.is do
    r.post do
      rodauth.require_authentication
      user_id = rodauth.logged_in?
      Graphic[request['graphic_id']]
          .add_variant(
              title: request['variant_title'],
              derived_from: request['variant_id'],
              long_description: request['variant_long_description']
          )
          .add_version(
              document: request['pages'].to_json,
              user_id: user_id
          ).values
    end
  end

  r.on Integer do |requested_id|

    r.get do
      requested_variant = Variant[requested_id].clone
      requested_variant[:parent_graphic] = requested_variant.graphic.values
      requested_variant[:tags] = Tagging.where(variant_id: 252).join(:tags, id: :tag_id).select(:tag_id, :name).map(&:values)
      requested_variant[:current_version] = Version
                                                .where(variant_id: requested_id)
                                                .order_by(:created_at)
                                                .limit(1)
                                                .last.values
      requested_variant.values
    end

    # POST /variants/:variant_id
    # login required, roles: all
    # Will create a new version for a variant if a variant ID is present,
    # or will create a new graphic with a new variant and a first version.
    # This is the default method of creating a completely new graphic. The
    # user_id will be read from the session.
    # @param document [String] The actual version of the variant as an SVG document
    # @param variant_id [Integer] The variant the version belongs to. If nil, will
    #   create an entirely new graphic. Then, title is required,
    # @param title [String] Required only if variant_id is nil. Title for
    #   the newly created graphic and variant.
    r.post do
        rodauth.require_authentication
        user_id = rodauth.logged_in?
        Variant[requested_id].add_version(
            document: request['pages'].to_json,
            user_id: user_id
        ).values
    end

  end
  # new variant

end