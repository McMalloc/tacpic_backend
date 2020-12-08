Tacpic.hash_branch "versions" do |r|
  # @request = JSON.parse r.body.read

  # TODO DEPRECATED
  # POST /versions
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
    Variant[request['variant_id']].add_version(
        document: request['pages'].to_json,
        user_id: user_id
    ).values
  end

  r.get do
    
  end
end

