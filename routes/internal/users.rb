Tacpic.hash_branch :internal, 'users' do |r|
  r.is do
    r.get do
      users = User.map(&:values)
      users.map do |user|
        name = user[:email].split('@').first
        domain = user[:email].split('@').last
        User.first.email.split('@').first
        user[:email] = name.gsub(/(?!^|.$)[^@\s]/, '_') + '@' + domain
        user
      end
    end
  end
end
