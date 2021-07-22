Tacpic.hash_branch :internal, 'logs' do |r|
  r.is String do |name|
    r.get do
      response['Content-Type'] = 'text/plain'
      File.read("#{ENV['APPLICATION_BASE']}/logs/#{name}")
    end
  end

  r.is do
    r.get do
      Dir["#{ENV['APPLICATION_BASE']}/logs/*"].map do |path|
        {
          name: File.basename(path),
          size: File.size(path)
        }
      end
    end
  end
end
