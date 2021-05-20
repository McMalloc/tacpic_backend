Tacpic.hash_branch 'quotes' do |r|
  # TODO: Funktion ist so auch in orders.rb definiert
  def get_quote(items)
    content_ids = items.map { |item| item['contentId'] }
    variants = Variant.where(id: content_ids).all
    missing_variants = content_ids - variants.map(&:id)

    Quote.new(items.filter_map { |item|
      !missing_variants.include?(item['contentId']) &&
      OrderItem.new(
        content_id: item['contentId'],
        product_id: item['productId'],
        quantity: item['quantity'] || 0
      )}, variants.map(&:values))
  end

  r.post 'request' do
    quote_request = QuoteRequest.create(
      user_id: rodauth.logged_in?,
      answer_address: request[:email] || nil,
      items: request[:items].to_json,
      comment: request[:comment]
    )

    if rodauth.logged_in?
      if request[:emailCopy]
        SMTP::SendMail.instance.send_quote_confirmation(
          User[rodauth.logged_in?].email, quote_request.id, request[:items]
        )
      end
    else
      SMTP::SendMail.instance.send_quote_confirmation(
        request[:email], quote_request.id, request[:items]
      )
    end

    response.status = 202
    quote_request.values
  end

  # POST /quotes
  r.post do
    if request[:items].count.zero?
      return {
        items: [],
        # packaging_item: {},
        postage_item: {},
        vat: 0,
        vat_reduced: 0,
        net_total: 0,
        gross_total: 0
      }
    end
    quote = get_quote request[:items]
    {
      items: quote.order_items.map(&:values),
      # packaging_item: quote.packaging_item.values,
      postage_item: quote.postage_item.values,
      vat: quote.vat,
      weight: quote.weight,
      vat_reduced: quote.reduced_vat,
      net_total: quote.net,
      gross_total: quote.gross
    }
  end
end
