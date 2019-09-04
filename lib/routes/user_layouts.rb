require_relative '../models/init' # gets Store

class Main < Sinatra::Base
  post '/user/layout' do
    $_db[:user_layouts].insert(
        user_id: 0, #@id,
        name: 'Layout',
        created_at: Date.today,
        layout: request.body.read
    )
    status 202
  end
end

