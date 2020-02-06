Tacpic.hash_branch "users" do |r|
  # @request = JSON.parse r.body.read

  # r.on Integer do |user_id|
  r.get 'validate' do
    {
        display_name: User[rodauth.logged_in?][:display_name],
        id: rodauth.logged_in?
    }
  end
  # end

  # GET users/versions
  # Gets all versions that the currently logged in user created. The result can be used to deduce the corresponding graphics and variants.
  r.on 'versions' do
    rodauth.require_authentication
    user_id = rodauth.logged_in?

    r.is do
      Version
          .select(
              Sequel[:versions][:id].as(:id),
              Sequel[:graphics][:title].as(:graphic_title),
              Sequel[:variants][:title].as(:variant_title),
              Sequel[:graphics][:id].as(:graphic_id),
              Sequel[:variants][:id].as(:variant_id),
              :long_description,
              :public,
              :description,
              Sequel[:variants][:created_at].as(:created_at),
              Sequel[:versions][:created_at].as(:updated_at))
          .join(:variants, id: :variant_id)
          .join(:graphics, id: :graphic_id)
          .where(user_id: user_id)
          .all.map(&:values)
    end

  end
end