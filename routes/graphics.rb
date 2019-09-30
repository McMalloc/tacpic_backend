Tacpic.route "graphics" do |r|
  # Gets Graphics based on its string descriptions or titles and based on tags attached to their variants.
  # @argument limit Integer
  # @argument offset Integer
  # @argument search Array[String] search terms for OR search
  # @argument tags Array[Integer] relevant tags
  r.get do
    puts "GET graphics/"
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
    # TODO: non public Varianten nicht durchsuchen

    result = Graphic
    variants = Variant
    tag_filtered_ids = nil

    unless r.params['tags'].nil?
      tag_ids = r.params['tags'].split(',').map(&:to_i)
      tag_filtered_ids = Tagging
                             .where(tag_id: tag_ids)
                             .group(:variant_id)
                             .select(:variant_id, :graphic_id, Sequel.lit("COUNT(variant_id) as count"))
                             .having(count: tag_ids.length)
                             .join(:variants, id: :variant_id)
                             .map { |t| t[:graphic_id] }
                             .uniq
      variants = variants.where(graphic_id: tag_filtered_ids)
    end

    # r.params['columns']
    if not r.params['search'].nil?
      match_string = "MATCH (variants.title, description, long_description) AGAINST ('#{r.params['search']}')"

      search_filtered_ids = variants
                                .select(
                                    Sequel[:graphics][:title].as(:graphic_title),
                                    Sequel[:variants][:title].as(:variant_title),
                                    Sequel[:variants][:id].as(:variant_id),
                                    Sequel[:graphics][:id].as(:graphic_id),
                                    :long_description,
                                    :description,
                                    Sequel.lit(match_string + " AS score"))
                                .join(:graphics, id: :graphic_id)
                                .where(Sequel.lit(match_string))
                                .order(Sequel.desc(:score)) # best score first
                                .map { |t| t[:graphic_id] }
                                .uniq
      result = result.where(id: search_filtered_ids)
    else
      result = result.order(Sequel.desc(:created_at)) # newest first
    end

    # TODO Vorschaubild
    # entweder mit SQL wie unten (aber dann welche Variante?) oder als ASSET unter fixer URL ablegen (z.B. assets/graphics/3/latest_preview) <- initialer Request kann schneller bearbeitet werden
    result = result
                 .select(:id, :title, :created_at, :variants_count)
                 .offset(r.params['offset'] || 0)
                 .limit(r.params['limit'])
                 .join(Sequel.lit("(SELECT graphic_id, COUNT(graphic_id) AS variants_count FROM `variants` GROUP BY graphic_id) AS counts ON (`counts`.`graphic_id` = `graphics`.`id`)"))

    # TODO last_updated hinzufügen
    result.all.map(&:values)
  end
  r.post do
    # POST /graphics
    # create a new graphic
    # todo auth
    @request = JSON.parse r.body.read

    @created_graphic = Graphic.create(
        title: @request['title'],
        # user_id: @request['user_id'], # graphics haben keine user_id mehr
        # description: @request['description']
    )

    @default_variant = @created_graphic.add_variant(
                                           title: @request['title'],
                                           public: false
    )

    response.status = 202 # created

    {
        created_graphic: @created_graphic,
        default_variant: @default_variant
    }
  end

  r.get Integer do |requested_id|
    puts "GET graphics/:id"
    {
        graphic: Graphic[requested_id].values,
        variants: Graphic[requested_id].variants.map(&:values)
    }
  end
end