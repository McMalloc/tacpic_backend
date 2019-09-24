class Tacpic < Roda
  route do |r|
    r.on "versions" do
      r.is do

        r.get do # "/"
          # there is no need for querying all versions
          response.status = 300
        end

        r.post do
          # todo auth
          @request = JSON.parse r.body.read



          @created_graphic = Graphic.create(
              title: @request['title'],
              user_id: @request['user_id'],
              description: @request['description']
          )

          response.status = 202 # created
          @created_graphic
        end

      end
    end
  end
end

