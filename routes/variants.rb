# require './helper/functions'

Tacpic.hash_branch 'variants' do |r|
  r.is do
    # POST /variants
    # login required, roles: all
    # Will create a new variant for the graphic with the supplied graphic id.
    r.post do
      rodauth.require_authentication
      user_id = rodauth.logged_in?

      graphic_no_of_pages = request[:pages].count
      graphic_format, graphic_landscape = Helper.determine_format request[:width], request[:height]
      braille_no_of_pages = request[:braillePages]['formatted'].select { |page| page.length > 0 }.length

      new_variant = Graphic[request['graphic_id']]
                    .add_variant(
                      title: request['variantTitle'],
                      derived_from: request['derivedFrom'],
                      description: request['variantDescription'],
                      medium: request[:medium],
                      braille_system: request[:system],
                      braille_format: 'a4',
                      graphic_no_of_pages: graphic_no_of_pages,
                      braille_no_of_pages: braille_no_of_pages,
                      graphic_format: graphic_format,
                      graphic_landscape: graphic_landscape
                    )

      request[:tags].each do |tag|
        if tag['tag_id'].nil?
          created_tag = Tag.create(
            name: tag['name'],
            user_id: user_id
          )
          tag['tag_id'] = created_tag[:id]
        end

        Tagging.create(
          user_id: user_id,
          tag_id: tag['tag_id'],
          variant_id: new_variant.id
        )
      end

      version = new_variant.add_version(
        document: Helper.pack_json(request, %w[pages braillePages keyedStrokes keyedTextures]),
        user_id: user_id
      )
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

    r.get /brf_.+/ do
      # rodauth.require_authentication
      # Authentifizierung abfragen, dann Datei generieren und Link zurückschicken?
      response['Content-Type'] = 'text/plain'
      Variant[requested_id].get_brf
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
      taggings = Tagging.where(variant_id: requested_id)
      tags = taggings.all.map { |tagging| tagging[:tag_id] }

      request[:tags].each do |tag|
        if tag['tag_id'].nil?
          created_tag = Tag.create(
            name: tag['name'],
            user_id: user_id,
            taxonomy_id: 1
          )

          tag['tag_id'] = created_tag[:id]
        end

        next if tags.include? tag['tag_id']

        Tagging.create(
          user_id: user_id,
          tag_id: tag['tag_id'],
          variant_id: requested_id
        )
      end

      ids_of_request = request[:tags].map { |tag| tag['tag_id'] }
      tags.each do |tag_id|
        taggings.where(tag_id: tag_id).delete unless ids_of_request.include? tag_id
      end

      graphic_no_of_pages = request[:pages].count
      graphic_format, graphic_landscape = Helper.determine_format request[:width], request[:height]
      braille_no_of_pages = request[:braillePages]['formatted'].select{|page| page.inject(''){|sum, line| sum + line}.strip.length > 0}.length

      Variant[requested_id].update(
        title: request[:variantTitle],
        description: request[:variantDescription],
        graphic_no_of_pages: graphic_no_of_pages,
        braille_no_of_pages: braille_no_of_pages,
        graphic_format: graphic_format,
        graphic_landscape: graphic_landscape,
        braille_system: request[:system],
        medium: request[:medium]
      )

      Graphic[request[:graphic_id]].update(title: request['graphicTitle']) if Variant[requested_id].derived_from.nil?

      version = Variant[requested_id].add_version(
        document: Helper.pack_json(request, %w[pages braillePages keyedStrokes keyedTextures]),
        # hash: request['hash'],
        change_message: request['changeMessage'] || nil,
        user_id: user_id
      )
      response.status = 201
      version.values
    end
  end
  # new variant
end
