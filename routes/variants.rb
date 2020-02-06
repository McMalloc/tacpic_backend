Tacpic.hash_branch "variants" do |r|

  r.get Integer do |requested_id|
    requested_variant = Variant[requested_id].clone
    requested_variant[:parent_graphic] = requested_variant.graphic.values
    requested_variant[:current_version] = Version
                                              .where(variant_id: requested_id)
                                              .order_by(:created_at)
                                              .limit(1)
                                              .last.values

    requested_variant.values
  end

end