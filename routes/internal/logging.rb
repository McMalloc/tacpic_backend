Tacpic.hash_branch :internal, 'logging' do |r|
  r.is do
    r.get do
      return "get logging"
    end

    r.post do
      logs = $_db[:frontend_errors]

      logs.insert(
        user_agent: request[:user_agent],
        platform: request[:platform],
        type: request[:error]['name'],
        frontend_version: request[:frontend_version],
        backend_version: request[:backend_version],
        message: request[:error]['message'],
        stacktrace: request[:error]['stack'],
        created_at: Time.now,
        ip_hash: Digest::MD5.hexdigest(request.ip)
      )

      "error logged"
    end
  end
end
