Tacpic.hash_branch "backend" do |r|
  # route: GET /backend/users
  r.on "users" do
    r.get do
      rodauth.require_authentication
      User[rodauth.logged_in?][:role] === 3
      @users = User.all
      view :index
    end
  end
end
