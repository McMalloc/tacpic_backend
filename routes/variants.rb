# require './helper/functions'

Tacpic.hash_branch 'variants' do |r|
  r.is do
    # POST /variants
    # login required, roles: all
    # Will create a new variant for the graphic with the supplied graphic id.
    r.post do
      rodauth.require_authentication
      user_id = rodauth.logged_in?

      file = TpFile.new request, user_id

      new_variant = file.create_variant
      file.create_taggings
      version = file.create_version

      response.status = 201
      version.values
    end 
  end

  r.on Integer do |requested_id|
    r.get 'history' do
      return {
        contributors: Variant[requested_id].contributors,
        versions: Variant[requested_id].versions.map(&:values)
      }
    end

    r.get /pdf_.+/ do
      # rodauth.require_authentication
      # Authentifizierung abfragen, dann Datei generieren und Link zurückschicken?
      response['Content-Type'] = 'application/pdf'
      Variant[requested_id].get_pdf
    end

    r.get /zip_.+/ do
      # rodauth.require_authentication
      # Authentifizierung abfragen, dann Datei generieren und Link zurückschicken?
      response['Content-Type'] = 'application/zip'
      Variant[requested_id].get_zip
    end

    r.get /brf_.+/ do
      # rodauth.require_authentication
      # Authentifizierung abfragen, dann Datei generieren und Link zurückschicken?
      response['Content-Type'] = 'text/plain'
      Variant[requested_id].get_brf
    end

    r.get /rtf_.+/ do
      # rodauth.require_authentication
      # Authentifizierung abfragen, dann Datei generieren und Link zurückschicken?
      response['Content-Type'] = 'application/rtf'
      Variant[requested_id].get_rtf
    end

    r.get do
      requested_variant = Variant[requested_id].clone
      requested_variant[:parent_graphic] = requested_variant.graphic.values
      requested_variant[:tags] = Tagging
                                 .where(variant_id: requested_id)
                                 .join(:tags, id: :tag_id)
                                 .select(:tag_id, :name).map(&:values) # { |tagging| tagging[:tag_id] }
      requested_variant[:current_version] = requested_variant.latest_version.values
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

      file = TpFile.new request, user_id
      file.update_taggings
      file.update_variant
      file.update_graphic User[user_id].role == CONSTANTS::ROLE::ADMIN
      version = file.create_version

      response.status = CONSTANTS::HTTP::CREATED
      version.values
    end
  end
  # new variant
end
