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

        where_clause = Sequel.lit("1=1")
        unless r.params['tags'].nil?
          tag_ids = r.params['tags'].split(',').map(&:to_i)
          relevant_graphic_ids = Tagging.where(tag_id: tag_ids).map{ |t| t.variant.graphic.id }.uniq
          where_clause = {id: relevant_graphic_ids}
        end

        set = Graphic

        # Liste aller betreffenden Varianten
        #             Graphic.association_join(:variants)
        # entsprecht: SELECT * FROM `graphics` INNER JOIN `variants` ON (`variants`.`graphic_id` = `graphics`.`id`);

        # r.params['columns'] = "description,title" # z.B.

        # r.params['columns'], wie unterscheiden zwischen Suche in Grafik / Suche in Varianten?

        unless r.params['search'].nil?
          # match_string = "MATCH (#{r.params['columns']}) AGAINST ('#{r.params['search']}')"
          match_string = "MATCH (title) AGAINST ('#{r.params['search']}')"
          set
              .where(where_clause)
              .association_join(:variants)
              .select(Sequel.lit("*, " + match_string + " AS score"))
              .where(Sequel.lit(match_string)) # optional > 1 für genauere Suchergebnisse
              .all
        end

        if r.params['limit'].nil? or not r.params['limit'].is_a? Integer
          response.status = 400 # Bad Request
          response['Content-Type'] = 'text/plain'
          response.write "Limit needs to be specified by an integer, like GET graphics?limit=10"
          r.halt
        end

        set
            .order(Sequel.desc(:created_at)) # newest first
            .offset(r.params['offset'] || 0)
            .limit(r.params['limit'])
            .all.map(&:values)
      end

      r.on Integer do |requested_id|

        r.get "variants" do
          puts "variants"
          Graphic[requested_id].variants.map{|v| v.values}
        end

        # GET /graphics/:id
        # get a graphic with requested id
        r.get do
          response.status = 200
          Graphic[requested_id].values
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

