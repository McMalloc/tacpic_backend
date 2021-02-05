Tacpic.hash_branch "graphics" do |r|

  # GET /graphics/:id
  # Gets single Graphic with requested ID
  # @argument requested_id Integer
  r.get Integer do |requested_id|
    variants = Graphic
                   .select(
                       Sequel[:graphics][:title].as(:graphic_title),
                       Sequel[:variants][:title].as(:variant_title),
                       Sequel[:graphics][:id].as(:graphic_id),
                       Sequel[:variants][:id].as(:variant_id),
                       :description,
                       Sequel[:variants][:created_at].as(:variant_created_at),
                       Sequel[:variants][:derived_from].as(:derived_from),
                       Sequel[:graphics][:created_at].as(:graphic_created_at),
                       Sequel[:graphics][:user_id].as(:original_author_id),
                       # Sequel[:variants][:user_id].as(:variant_author_id),
                       :braille_system, :graphic_no_of_pages, :graphic_format,
                       :graphic_landscape, :braille_no_of_pages, :braille_format, :current_file_name,
                       Sequel.lit("array_agg(taggings.tag_id) AS tags")
                   )
                   .where(graphic_id: requested_id)
                   .join(:variants, graphic_id: :id)
                   .left_join(:taggings, variant_id: :id)
                   .group_by(:graphic_title,
                             :variant_title,
                             :variant_created_at,
                             :current_file_name,
                             :graphic_created_at,
                             :derived_from,
                             :description,
                             :original_author_id,
                             # :variant_author_id,
                             :braille_system, :graphic_no_of_pages, :graphic_format,
                             :graphic_landscape, :braille_no_of_pages, :braille_format, :current_file_name,
                             Sequel[:graphics][:id],
                             Sequel[:variants][:id])
                   .all


    {
        id: variants[0][:graphic_id],
        title: variants[0][:graphic_title],
        created_at: variants[0][:graphic_created_at],
        original_author_id: variants[0][:original_author_id],
        variants: variants.map { |variant|
          price = PriceCalculator.new variant, true
          {
              id: variant[:variant_id],
              quote: price.gross.ceil,
              quote_graphics_only: price.gross_graphics_only.ceil,
              # TODO ineffizient, oder zumindest kann hiermit die query oben vereinfacht werden
              document: JSON.parse(Version.where(variant_id: variant[:variant_id]).last.document),
              braille_format: variant[:braille_format],
              current_file_name: variant[:current_file_name],
              braille_no_of_pages: variant[:braille_no_of_pages],
              graphic_format: variant[:graphic_format],
              graphic_landscape: variant[:graphic_landscape],
              derived_from: variant[:derived_from],
              graphic_no_of_pages: variant[:graphic_no_of_pages],
              title: variant[:variant_title],
              created_at: variant[:variant_created_at],
              description: variant[:description],
              system: variant[:braille_system],
              tags: variant[:tags].scan(/[0-9]+/).map { |match| match.to_i } #TODO funktioniert mit ID 10+ ?
          } },
    }
  end

  # Gets Graphics based on its string descriptions or titles and based on tags attached to their variants.
  # @argument limit Integer
  # @argument offset Integer
  # @argument search Array[String] search terms for OR search
  # @argument tags Array[Integer] relevant tags
  # @argument variants Array[Integer] specific variants
  r.get do
    # TODO boolean Suche mit erweiterter Suchsyntax
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
      term = r.params['search'].strip
      where_clause = where_clause + %Q{
        WHERE (variants.title       ILIKE '%#{term}%' OR
              variants.description ILIKE '%#{term}%' OR
              graphics.title       ILIKE '%#{term}%' OR
              "tags"."name"        ILIKE '%#{term}%')
      }
    end

    # specific variants requested
    unless r.params['variants'].nil? || r.params['variants'].length == 0
      where_clause = where_clause + %Q{
        WHERE (variants.id IN (#{r.params['variants']}))
      }
    end

    # paper format
    unless r.params['format'].nil? || r.params['format'].length == 0
      formats = r.params['format'].split ','
      where_clause = where_clause + "#{where_clause.length == 0 ? 'WHERE (' : 'AND ('}"

      formats.each_with_index do |format, index|
        where_clause = where_clause + %Q{#{index == 0 ? '' : 'OR'}
          (variants.graphic_format = '#{format}')
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

    # bezieht sich auf auf die join table, genaue anzahl nicht bestimmbar
    limit_clause = 'LIMIT 50'
    unless r.params['limit'].nil? || r.params['limit'].length == 0
      limit_clause = "LIMIT #{r.params['limit'].to_i}"
    end

    offset_clause = 'OFFSET 0'
    unless r.params['offset'].nil? || r.params['offset'].length == 0
      offset_clause = "OFFSET #{r.params['offset'].to_i}"
    end

    # TODO wird nicht mehr alles gebraucht, kann entschlackt werden
    begin
      $_db.fetch(
          %Q{
          SELECT "graphics"."title"                       AS "graphic_title",
                 "variants"."title"                       AS "variant_title",
                 "graphics"."id"                          AS "graphic_id",
                 "graphics"."user_id"                     AS "original_author_id",
                 "variants"."id"                          AS "variant_id",
                 "variants"."description"                 AS "variant_description",
                 "variants"."braille_system"              AS "system",
                 "variants"."graphic_no_of_pages"         AS "graphic_no_of_pages",
                 "variants"."graphic_format"              AS "graphic_format",
                 "variants"."graphic_landscape"           AS "graphic_landscape",
                 "variants"."braille_no_of_pages"         AS "braille_no_of_pages",
                 "variants"."braille_format"              AS "braille_format",
                 "variants"."current_file_name"           AS "current_file_name",
                 "variants"."created_at"                  AS "created_at",
                  array_agg(taggings.tag_id)              AS tags,
                  array_agg("tags"."name")                AS tag_names
          FROM "graphics"
          INNER JOIN #{subquery} variants ON ("graphics"."id" = "variants"."graphic_id")
          LEFT JOIN "taggings" ON ("taggings"."variant_id" = "variants"."id")
          LEFT JOIN "tags" ON ("taggings"."tag_id" = "tags"."id")
          #{where_clause}
          GROUP BY "graphics"."title", "variants"."title", "graphics"."id", "variants"."id", "variants"."description",
                   "variants"."created_at", "variants"."braille_system", "variants"."graphic_no_of_pages", "variants"."graphic_format",
                   "variants"."graphic_landscape", "variants"."braille_no_of_pages", "variants"."braille_format", "variants"."current_file_name"
          ORDER BY "variants"."created_at" DESC
          #{limit_clause}
          #{offset_clause}
          }
      ).all
    rescue Sequel::Error
      pp $!.message
    end
  end

  # POST /graphics
  # create a new graphic 
  r.post do
    begin
      rodauth.require_authentication
      user_id = rodauth.logged_in?

      file = TpFile.new request, user_id

      created_graphic = file.create_graphic
      default_variant = file.create_variant
      file.create_taggings
      first_version = file.create_version

      response.status = 201 # created
      {
          created_graphic: created_graphic.values,
          default_variant: default_variant.values,
          first_version: first_version.values
      }

    rescue StandardError => e
      response.status = 500
      e.to_json
    end
  end
end