class Main < Sinatra::Base
  get '/' do
    # $_db[:user_layouts].insert(
    #     user_id: @id,
    #     name: 'Layout',
    #     created_at: Date.today,
    #     layout: request.body.read
    # )
    status 202
  end
end

