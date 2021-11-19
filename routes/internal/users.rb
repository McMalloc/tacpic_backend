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

  r.on Integer do |id|
    r.get do
      {
        **User[id].values,
        rights: User[id].user_rights.values
      }
    end

    r.post 'rpc' do
      case request[:method]
        when 'change_rights'
          current_set = User[id].user_rights
          current_set[request[:right].to_sym] = !request[:value]
          current_set.save_changes
          return {
            **User[id].values,
            rights: User[id].user_rights.values
          }
        else
          response.status = CONSTANTS::HTTP::BAD_REQUEST
          return {
            type: 'unknown_method',
            message: 'unknown_method_message'
          }
      end
    end
  end
end
