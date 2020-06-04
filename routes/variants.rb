require './processing/Document'
require './helper/functions'

Tacpic.hash_branch "variants" do |r|

  r.is do
    # POST /variants
    # login required, roles: all
    # Will create a new variant for the graphic with the supplied graphic id.
    r.post do
      rodauth.require_authentication
      user_id = rodauth.logged_in?
      new_variant = Graphic[request['graphic_id']]
                        .add_variant(
                            title: request['variantTitle'],
                            derived_from: request['variant_id'],
                            description: request['variantDescription'],
                            medium: request[:medium],
                            braille_system: request[:system],
                            width: request[:width],
                            height: request[:height],
                        )

      Document.save_files request['graphic_id'], new_variant.id,
                          request['pages'],
                          request['width'],
                          request['height'],
                          request['braillePages']

      version = new_variant.add_version(
          document: Helper.pack_json(request, %w(pages braillePages keyedStrokes keyedTextures)),
          user_id: user_id
      )
      response.status = 201
      version.values
    end
  end

  r.on Integer do |requested_id|

    r.get 'pdf' do
      # rodauth.require_authentication
      # Authentifizierung abfragen, dann Datei generieren und Link zurückschicken?
      response['Content-Type'] = 'application/pdf'
      Document.get_pdf(Variant[requested_id].graphic_id, requested_id)
    end

    r.get 'brf' do
      # rodauth.require_authentication
      # Authentifizierung abfragen, dann Datei generieren und Link zurückschicken?
      response['Content-Type'] = 'text/plain'
      Document.get_brf(Variant[requested_id].graphic_id, requested_id)
    end

    r.get do
      requested_variant = Variant[requested_id].clone
      requested_variant[:parent_graphic] = requested_variant.graphic.values
      requested_variant[:tags] = Tagging
                                     .where(variant_id: requested_id)
                                     .join(:tags, id: :tag_id)
                                     .select(:tag_id, :name).map(&:values)# { |tagging| tagging[:tag_id] }
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

      Document.save_files request['graphic_id'], requested_id,
                          request['pages'],
                          request['width'],
                          request['height'],
                          request['braillePages']


      taggings = Tagging.where(variant_id: requested_id)
      tags = taggings.all.map { |tagging| tagging[:tag_id] }

      request[:tags].each { |tag|
        if tag['tag_id'].nil?
          created_tag = Tag.create(
              name: tag['name'],
              user_id: user_id,
              taxonomy_id: 4
          )

          tag['tag_id'] = created_tag[:id]
        end

        unless tags.include? tag['tag_id']
          Tagging.create(
              user_id: user_id,
              tag_id: tag['tag_id'],
              variant_id: requested_id
          )
        end
      }

      ids_of_request = request[:tags].map { |tag| tag['tag_id'] }
      tags.each { |tag_id|
        unless ids_of_request.include? tag_id
          taggings.where(tag_id: tag_id).delete
        end
      }

      Variant[requested_id].update(
          title: request[:variantTitle],
          description: request[:variantDescription],
          width: request[:width],
          height: request[:height],
          braille_system: request[:system],
          medium: request[:medium]
      )

      version = Variant[requested_id].add_version(
          document: Helper.pack_json(request, %w(pages braillePages keyedStrokes keyedTextures)),
          user_id: user_id
      )
      response.status = 201
      version.values
    end

  end
# new variant

end