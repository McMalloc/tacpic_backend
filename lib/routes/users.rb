class Tacpic < Sinatra::Base
  namespace '/users' do
    before do
      request.body.rewind
      @request_payload = JSON.parse(request.body.read)[0]
    end

    # Get all users
    get do
      status 401
    end

    # Get specific user
    get '/:id' do

    end

    # create new user
    post do
      User.new do |u|
        u.email = @request_payload.email
        u.password = @request_payload.password
      end

      status 202
      @user.to_json
    end
  end
end