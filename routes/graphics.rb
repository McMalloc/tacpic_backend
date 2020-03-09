Tacpic.hash_branch "graphics" do |r|

  r.get Integer do |requested_id|
    {
        graphic: Graphic[requested_id].values,
        variants: Graphic[requested_id].variants.map(&:values)
    }
  end

  # Gets Graphics based on its string descriptions or titles and based on tags attached to their variants.
  # @argument limit Integer
  # @argument offset Integer
  # @argument search Array[String] search terms for OR search
  # @argument tags Array[Integer] relevant tags
  r.get do
    # TODO boolean Suche mit erweiterter Suchsyntax

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

    where_clause = "WHERE (graphics.user_id = #{user_id})"
    unless r.params['search'].nil? || r.params['search'].length == 0
      term = r.params['search']
      where_clause = where_clause + %Q{
        AND  (variants.title       ILIKE '%#{term}%' OR
              variants.description ILIKE '%#{term}%' OR
              graphics.title       ILIKE '%#{term}%' OR
              graphics.description ILIKE '%#{term}%' OR
              "tags"."name"        ILIKE '%#{term}%')
      }
    end

    limit_clause = 'LIMIT 20'
    unless r.params['limit'].nil? || r.params['limit'].length == 0
      limit_clause = "LIMIT #{r.params['limit'].to_i}"
    end

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
                 "graphics"."description"   AS "graphic_description",
                 "variants"."created_at"    AS "created_at",
                  array_agg(taggings.tag_id) AS tags,
                  array_agg("tags"."name")  AS tag_names
          FROM "graphics"
          INNER JOIN #{subquery} variants ON ("graphics"."id" = "variants"."graphic_id")
          LEFT JOIN "taggings" ON ("taggings"."variant_id" = "variants"."id")
          LEFT JOIN "tags" ON ("taggings"."tag_id" = "tags"."id")
          #{where_clause}
          GROUP BY "graphics"."title", "variants"."title", "graphics"."id", "variants"."id", "variants"."description",
                   "graphics"."description", "variants"."created_at", "variants"."braille_system", "variants"."width", "variants"."height"
          ORDER BY "variants"."created_at"
          #{limit_clause}
        }
    ).all
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