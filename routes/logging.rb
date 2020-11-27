Tacpic.hash_branch "logging" do |r|
    r.is do
      r.post do
        puts request[:platform]
      end
    end
  end