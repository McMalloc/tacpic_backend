Tacpic.hash_branch :internal, 'orders' do |r|
  r.is do
    r.get do
      Order.all.map(&:values)
    end
  end
end
