class TpFile
    attr_reader :variant
    attr_reader :version

    def initialize(request, user_id)
        @request = request

        @tags = request[:tags]
        @width = request[:width].to_i
        @height = request[:height].to_i

        @user_id = user_id

        @graphic_id = request[:graphic_id].to_i
        @variant_id = request[:variant_id].to_i
    end

    def determine_page_count
        @request[:pages].count
    end

    def determine_format
        format = nil
        if (@width == 210 and @height == 297) or (@width == 297 and @height == 210) 
            format = 'a4' 
        end
    
        if (@width == 420 and @height == 297) or (@width == 297 and @height == 420) 
            format = 'a3' 
        end

        return format
    end

    # isLandscape?
    def determine_orientation
        return @width > @height
    end

    def determine_braille_page_count
        @request[:braillePages]['formatted'].select { 
            |page| page.length > 0 
        }.length
    end

    def self.pack_json(request, fields)
        stripped_request = {}
        fields.each do |field|
          stripped_request[field] = request[field]
        end
        return stripped_request.to_json
    end

    def create_graphic
        graphic = Graphic.create(
          title: @request[:graphicTitle],
          user_id: @user_id
        )
        @graphic_id = graphic.id
        return graphic
    end

    def update_graphic
        Graphic[@graphic_id]
            .update(title: @request['graphicTitle']) if Variant[@variant_id].derived_from.nil?
    end

    def create_variant
        @variant = Graphic[@graphic_id]
            .add_variant(
                title: @request['variantTitle'],
            derived_from: @request['derivedFrom'],
            description: @request['variantDescription'],
            medium: 'swell',
            braille_system: @request[:system],
            braille_format: 'a4',
            graphic_no_of_pages: determine_page_count,
            braille_no_of_pages: determine_braille_page_count,
            graphic_format: determine_format,
            graphic_landscape: determine_orientation
            )

        return @variant
    end

    def update_variant
        Variant[@variant_id].update(
            title: @request['variantTitle'],
            description: @request['variantDescription'],
            medium: 'swell',
            braille_system: @request[:system],
            braille_format: 'a4',
            graphic_no_of_pages: determine_page_count,
            braille_no_of_pages: determine_braille_page_count,
            graphic_format: determine_format,
            graphic_landscape: determine_orientation
          )
    end

    def create_version
        packed_request = {}
        %w[pages braillePages keyedStrokes keyedTextures].each do |field|
            packed_request[field] = @request[field]
        end
        Variant[@variant_id].add_version(
            document: packed_request.to_json,
            change_message: @request['changeMessage'] || nil,
            user_id: @user_id
        )
    end

    def create_taggings
        @tags.each do |tag|
            if tag['tag_id'].nil?
              created_tag = Tag.create(
                name: tag['name'],
                user_id: @user_id
              )
              tag['tag_id'] = created_tag.id
            end
    
            Tagging.create(
              user_id: @user_id,
              tag_id: tag['tag_id'],
              variant_id: @variant.id
            )
          end
    end

    def update_taggings
        taggings = Tagging.where(variant_id: @variant_id)
        tagging_ids = taggings.all.map { |tagging| tagging[:tag_id] }
        @tags.each do |tag|
            if tag['tag_id'].nil?
              created_tag = Tag.create(
                name: tag['name'],
                user_id: @user_id,
                taxonomy_id: 1
              )
    
              tag['tag_id'] = created_tag.id
            end
    
            next if tagging_ids.include? tag['tag_id']
    
            Tagging.create(
              user_id: @user_id,
              tag_id: tag['tag_id'],
              variant_id: @variant_id
            )
          end
    
          ids_of_request = @tags.map { |tag| tag['tag_id'] }
          tagging_ids.each do |tag_id|
            taggings.where(tag_id: tag_id).delete unless ids_of_request.include? tag_id
          end
    end

end