class Tacpic < Roda
  route do |r|
    r.on "graphics" do

      r.get do
        # TODO limit. alle Grafiken sollten nicht geladen werden, um den Server nicht zu belasten
        # orders:   by download count (accumulated version download count)
        #           by approval count of variants
        #           by date
        puts r.params['tags']
        Graphic
            .order(Sequel.desc(:created_at)) # newest first
            .offset(r.params['offset'] || 0)
            .limit(r.params['limit'] || Graphic.all.length - 1)
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

