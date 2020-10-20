Tacpic.hash_branch "legal" do |r|
  r.on do
    r.get 'index' do
      LegalAPI.instance.index
    end

    r.get String do |lang|
      LegalAPI.instance.index
    end

    r.get String, String do |lang, title|
      LegalAPI.instance.get_file title
    end
  end
end