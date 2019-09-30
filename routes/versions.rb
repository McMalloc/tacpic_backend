Tacpic.route "versions" do |r|
  @request = JSON.parse r.body.read

  r.post do
    if @request['variant_id'].nil?
      title = @request['title'] || "Unbenannte Grafik"

      @created_graphic = Graphic.create(
          title: @request['title'],
      # user_id: @request['user_id'], # graphics haben keine user_id mehr
      # description: @request['description']
          )

      @default_variant = @created_graphic.add_variant(
          title: @request['title'],
          public: false
      )

      @default_variant.add_version(
                          document: @request['document'],
                          change_message: "Erste Version"
      )
    else
      Variant[@request['variant_id']].add_version(
          document: @request['document'],
          user_id: @user.id, # TODO woher kommt das User Objekt?
          change_message: @request['change_message']
      )
    end
  end
end

