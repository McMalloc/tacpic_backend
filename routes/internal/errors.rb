Tacpic.hash_branch :internal, 'errors' do |r|
  r.get 'frontend' do
    return $_db[:frontend_errors].all
  end
  r.get 'backend' do
    return $_db[:backend_errors].all
  end
end
