Tacpic.hash_branch :internal, 'variants' do |r|
  r.on Integer do |requested_id|
    r.post do
      Variant[requested_id].update({
                                     public: request[:public]
                                   })
    end
  end
end
