class Tacpic < Roda
  route do |r|
    r.on "graphics" do
      # Gets Graphics based on its string descriptions or titles and based on tags attached to their variants.
      # @argument limit Integer
      # @argument offset Integer
      # @argument search Array[String] search terms for OR search
      # @argument tags Array[Integer] relevant tags
      r.get do
        # TODO Suche für gewählte Tags oder Freitext (zur Zeit: Freitext auf Basis der nach Tags gefilterten Grafiken)
        # TODO boolean Suche mit erweiterter Suchsyntax
        # TODO: sortieren danach, ob eine Variante alle tags erfüllt

        if r.params['limit'].nil? or not Integer(r.params['limit'])
          response.status = 400 # Bad Request
          response['Content-Type'] = 'text/plain'
          response.write "Limit needs to be specified by an integer, like GET graphics?limit=10"
          r.halt
        end

        # TODO: sortieren danach, ob eine Variante alle tags erfüllt

        result = $_db["SELECT id, first, title, description, graphics_with_counts_and_first.created_at, variants_count, document FROM
(SELECT * FROM # first, counts

    (SELECT graphic_id, MIN(id) AS first # first variant_id, graphic_id
    FROM variants
    GROUP BY graphic_id) AS first_variant

INNER JOIN (
    SELECT * FROM graphics # graphic values, count
                      INNER JOIN (SELECT graphic_id AS graphic_id_counted, COUNT(graphic_id) AS variants_count
                                  FROM `variants`
                                  GROUP BY graphic_id) AS counts
                                 ON (`counts`.`graphic_id_counted` = `graphics`.`id`)
    ) AS variant_counts
ON first_variant.graphic_id = variant_counts.id) AS graphics_with_counts_and_first

INNER JOIN

    (SELECT versions.variant_id, document, versions.created_at, graphic_id # graphic_id, variant_id, document
    FROM (SELECT variant_id, MAX(created_at) AS created_at
        FROM versions
        GROUP BY variant_id) AS latest_version
        INNER JOIN versions
    ON
        versions.variant_id = latest_version.variant_id AND
        versions.created_at = latest_version.created_at
        JOIN variants
        ON versions.variant_id = variants.id) AS previews


ON graphics_with_counts_and_first.id = previews.graphic_id AND
   graphics_with_counts_and_first.first = previews.variant_id"]

        unless r.params['tags'].nil?
          tag_ids = r.params['tags'].split(',').map(&:to_i)
          counts = $_db["SELECT *, COUNT(id) AS tag_count FROM variants AS variants INNER JOIN (SELECT variant_id FROM `taggings` WHERE tag_id IN (#{tag_ids.join(',')})) AS taggings ON (`taggings`.`variant_id` = `variants`.`id`) GROUP BY variants.id HAVING tag_count = #{tag_ids.length}"]
          # counts = $_db["SELECT *, COUNT(id) AS tag_count FROM variants AS variants INNER JOIN (SELECT variant_id FROM `taggings` WHERE tag_id IN (#{tag_ids.join(',')})) AS taggings ON (`taggings`.`variant_id` = `variants`.`id`) GROUP BY variants.id HAVING tag_count = #{tag_ids.length}"]
          result = result.where({id: counts.map{|count| count[:graphic_id]}})
        end

        if not r.params['search'].nil?
          match_string = "MATCH (#{r.params['columns'] || "title"}) AGAINST ('#{r.params['search']}')"
          result = result # .select(Sequel.as(:id, 'graphic_id')) # .association_join(:variants) # noch nicht, ist vielleicht gerade zu kompliziert, da sonst auch gewichtet gesucht wird
              .select(Sequel.lit("*, " + match_string + " AS score"))
              .where(Sequel.lit(match_string)) # optional > 1 für genauere Suchergebnisse
              .order(Sequel.desc(:score))
        else
          result = result.order(Sequel.desc(:created_at)) # newest first
        end

        # .select(Sequel.as(:id, 'graphic_id'))
        # SELECT * FROM (SELECT id, title as graphics__title FROM `graphics`) AS graphics
        # INNER JOIN (SELECT graphic_id, id AS variants__id, title FROM `variants`) AS variants
        # ON (`variants`.`graphic_id` = `graphics`.`id`);

        # TODO Vorschaubild
        # entweder mit SQL wie unten (aber dann welche Variante?) oder als ASSET unter fixer URL ablegen (z.B. assets/graphics/3/latest_preview)
        result = result
            .offset(r.params['offset'] || 0)
            .limit(r.params['limit']) # .join(Sequel.lit("(SELECT graphic_id, COUNT(graphic_id) AS count FROM `variants` GROUP BY graphic_id) AS counts ON (`counts`.`graphic_id` = `graphics`.`id`)"))
            # .join(Sequel.lit("(SELECT graphic_id, COUNT(graphic_id) AS variants_count FROM `variants` GROUP BY graphic_id) AS counts ON (`counts`.`graphic_id` = `graphics`.`id`)"))

        result.all.map(&:values)
      end

      r.on Integer do |requested_id|

        # GET /graphics/:id
        # get a graphic and variants with requested id
        r.get do
          {
              graphic: Graphic[requested_id].values,
              variants: Graphic[requested_id].variants.map(&:values)
          }
        end
      end

      r.post do
        # todo auth
        @request = JSON.parse r.body.read

        @created_graphic = Graphic.create(
            title: @request['title'],
            # user_id: @request['user_id'], # graphics haben keine user_id mehr
            description: @request['description']
        )

        response.status = 202 # created
        @created_graphic
      end

      # POST /graphics
      # create a new graphic
    end
  end
end

# SQL Code for receiving latest version per variant
# SELECT
#     versions.variant_id, document, versions.created_at, graphic_id #document, user_id, versions.id as version__id, versions.created_at, versions.variant_id
# FROM
#     (SELECT
#          variant_id, MAX(created_at) AS created_at
#      FROM
#          versions
#      GROUP BY
#          variant_id) AS latest_version
#         INNER JOIN
#     versions
#     ON
#                 versions.variant_id = latest_version.variant_id AND
#                 versions.created_at = latest_version.created_at
# JOIN
#         variants
# ON
#         versions.variant_id = variants.id;