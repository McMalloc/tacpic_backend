Tacpic.hash_branch "graphics" do |r|

  r.get Integer do |requested_id|
    variants = Graphic
                   .select(
                       Sequel[:graphics][:title].as(:graphic_title),
                       Sequel[:variants][:title].as(:variant_title),
                       Sequel[:graphics][:id].as(:graphic_id),
                       Sequel[:variants][:id].as(:variant_id),
                       :description,
                       Sequel[:variants][:created_at].as(:variant_created_at),
                       Sequel[:graphics][:created_at].as(:graphic_created_at),
                       Sequel[:graphics][:user_id].as(:original_author_id),
                       # Sequel[:variants][:user_id].as(:variant_author_id),
                       :braille_system, :width, :height,
                       Sequel.lit("array_agg(taggings.tag_id) AS tags")
                   )
                   .where(graphic_id: requested_id)
                   .join(:variants, graphic_id: :id)
                   .left_join(:taggings, variant_id: :id)
                   .group_by(:graphic_title,
                             :variant_title,
                             :variant_created_at,
                             :graphic_created_at,
                             :description,
                             :original_author_id,
                             # :variant_author_id,
                             :braille_system, :width, :height,
                             Sequel[:graphics][:id],
                             Sequel[:variants][:id])
                   .all

    {
        id: variants[0][:graphic_id],
        title: variants[0][:graphic_title],
        created_at: variants[0][:graphic_created_at],
        original_author_id: variants[0][:original_author_id],
        variants: variants.map {|variant| {
            id: variant[:variant_id],
            title: variant[:variant_title],
            description: variant[:description],
            system: variant[:braille_system],
            width: variant[:width],
            height: variant[:height],
            tags: variant[:tags].scan(/[0-9]+/).map {|match| match.to_i}
        }},
    }
  end

  # Gets Graphics based on its string descriptions or titles and based on tags attached to their variants.
  # @argument limit Integer
  # @argument offset Integer
  # @argument search Array[String] search terms for OR search
  # @argument tags Array[Integer] relevant tags
  r.get do
    # TODO boolean Suche mit erweiterter Suchsyntax

    response['Access-Control-Allow-Origin'] = 'http://localhost:3000'
    rodauth.require_authentication
    user_id = rodauth.logged_in?

    subquery = ''
    unless r.params['tags'].nil? || r.params['tags'].length == 0
      tag_ids = r.params['tags'].split(',').map(&:to_i)
      subquery = %Q{(SELECT v.*
                    FROM variants v,
                                  taggings tg,
                                  tags t
                    WHERE tg.tag_id = t.id
                    AND (t.id IN (#{tag_ids.join(',')}))
                    AND v.id = tg.variant_id
                    GROUP BY v.id
                    HAVING COUNT(v.id) = #{tag_ids.count}) as }
    end

    where_clause = ""

    # where_clause = "WHERE (graphics.user_id = #{user_id})"
    unless r.params['search'].nil? || r.params['search'].length == 0
      term = r.params['search']
      where_clause = where_clause + %Q{
        WHERE (variants.title       ILIKE '%#{term}%' OR
              variants.description ILIKE '%#{term}%' OR
              graphics.title       ILIKE '%#{term}%' OR
              "tags"."name"        ILIKE '%#{term}%')
      }
    end

    # paper format
    unless r.params['format'].nil? || r.params['format'].length == 0
      format_mapping = {
          'a4': [210, 297],
          'a3': [297, 420]
      }
      formats = r.params['format'].split ','
      where_clause = where_clause + "#{where_clause.length == 0 ? 'WHERE (' : 'AND ('}"

      formats.each_with_index do |format, index|
        format = format.to_sym
        where_clause = where_clause + %Q{#{index == 0 ? '' : 'OR'}
          (variants.width = #{format_mapping[format][0]} AND variants.height = #{format_mapping[format][1]}) OR
          (variants.width = #{format_mapping[format][1]} AND variants.height = #{format_mapping[format][0]})
        }
      end
      where_clause = where_clause + ') '
    end

    # braille system
    # TODO make mapping independent from liblouis filenames
    unless r.params['system'].nil? || r.params['system'].length == 0
      systems = r.params['system'].split ','
      where_clause = where_clause + "#{where_clause.length == 0 ? 'WHERE (' : 'AND ('}"

      systems.each_with_index do |system, index|
        where_clause = where_clause + %Q{#{index == 0 ? '' : 'OR'}
          (variants.braille_system = '#{system}')
        }
      end

      where_clause = where_clause + ') '
    end

    puts where_clause

    # bezieht sich auf auf die join table, genaue anzahl nicht bestimmbar
    limit_clause = 'LIMIT 50'
    unless r.params['limit'].nil? || r.params['limit'].length == 0
      limit_clause = "LIMIT #{r.params['limit'].to_i}"
    end

    # TODO wird nicht mehr alles gebraucht, kann entschlackt werden
    begin
      $_db.fetch(
          %Q{
          SELECT "graphics"."title"         AS "graphic_title",
                 "variants"."title"         AS "variant_title",
                 "graphics"."id"            AS "graphic_id",
                 "graphics"."user_id"       AS "original_author_id",
                 "variants"."id"            AS "variant_id",
                 "variants"."description"   AS "variant_description",
                 "variants"."braille_system"AS "system",
                 "variants"."width"         AS "width",
                 "variants"."height"        AS "height",
                 "variants"."created_at"    AS "created_at",
                  array_agg(taggings.tag_id) AS tags,
                  array_agg("tags"."name")  AS tag_names
          FROM "graphics"
          INNER JOIN #{subquery} variants ON ("graphics"."id" = "variants"."graphic_id")
          LEFT JOIN "taggings" ON ("taggings"."variant_id" = "variants"."id")
          LEFT JOIN "tags" ON ("taggings"."tag_id" = "tags"."id")
          #{where_clause}
          GROUP BY "graphics"."title", "variants"."title", "graphics"."id", "variants"."id", "variants"."description",
                   "variants"."created_at", "variants"."braille_system", "variants"."width", "variants"."height"
          ORDER BY "variants"."created_at"
          #{limit_clause}
          }
      ).all
    rescue Sequel::Error
      pp $!.message
    end
  end

  # POST /graphics
  # create a new graphic
  r.post do
    rodauth.require_authentication
    user_id = rodauth.logged_in?

    created_graphic = Graphic.create(
        title: request[:graphicTitle],
        user_id: user_id,
        description: request[:graphicDescription]
    )

    default_variant = created_graphic.add_variant(
        title: 'Basis', # TODO i18n
        public: false,
        description: nil,
        medium: request[:medium],
        braille_system: request[:system],
        width: request[:width],
        height: request[:height]
    )

    # TAGS
    request[:tags].each { |tag|
      if tag['tag_id'].nil?
        created_tag = Tag.create(
            name: tag['name'],
            user_id: user_id,
            taxonomy_id: 4
        )

        tag['tag_id'] = created_tag[:id]
      end
      Tagging.create(
          user_id: user_id,
          tag_id: tag['tag_id'],
          variant_id: default_variant.id
      )
    }

    # FIRST VERSION
    first_version = default_variant.add_version(
        document: request[:pages].to_json,
        user_id: user_id)

    Document.save_svg default_variant.id,
                      request['renderedPreview'],
                      request['width'],
                      request['height']

    response.status = 201 # created

    {
        created_graphic: created_graphic.values,
        default_variant: default_variant.values,
        first_version: first_version.values
    }
  end
end