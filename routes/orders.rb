Tacpic.hash_branch 'orders' do |r|
  # GET /orders/:id/finalise?hash=xyz
  r.get Integer, 'finalise' do |id|
    if Order[id].get_hash == request['hash']
      if Order[id].status >= CONSTANTS::ORDER_STATUS::PRODUCED
        return "Produktionsauftrag wurde bereits bestaetigt.<br /><p>Technische Informationen</p><pre>#{Order[id].values.to_yaml}</pre>"
      else
        Order[id].update(status: CONSTANTS::ORDER_STATUS::PRODUCED)
        SMTP::SendMail.instance.send_invoice_to_accounting(Order[id].invoices.last)
        return 'Produktionsauftrag bestaetigt.'
      end
    else
      response.status = CONSTANTS::HTTP::NOT_ACCEPTABLE
      logs = $_db[:backend_errors]
      logs.insert(
        method: 'PRODUCTION',
        path: "/orders/#{id}/finalise",
        params: request['hash'],
        frontend_version: 'na',
        backend_version: $_version,
        type: 'HTTP 406',
        message: 'finalisation failed: wrong or missing hash',
        created_at: Time.now
      )
      return CONSTANTS::HTTP::NOT_ACCEPTABLE.to_s + ': Ungueltig. Bitte Link ueberpruefen.'
    end
  end

  r.get do
    rodauth.require_authentication
    Invoice.join(:orders, id: :order_id).where(user_id: rodauth.logged_in?).map(&:values)
  end

  # GET /orders/:id/invoice_link
  r.get Integer, 'invoice_link' do |_id|
    rodauth.require_authentication
    user_id = rodauth.logged_in?
    return 'hey'
  end

  # GET /orders/:id
  r.get Integer do |id|
    rodauth.require_authentication
    user_id = rodauth.logged_in?
    if (User[user_id][:role] == CONSTANTS::ROLE::ADMIN) || (Orders[id][:user_id] == user_id)
      Orders[id].values
    else
      response.status = CONSTANTS::HTTP::FORBIDDEN # Forbidden
      response.write 'not authorized' # TODO: systematic error messages
      request.halt
    end
  end

  def get_quote(items)
    content_ids = items.map { |item| item['contentId'] }
    variants = Variant.where(id: content_ids).all
    missing_variants = content_ids - variants.map(&:id)

    Quote.new(items.filter_map do |item|
                !missing_variants.include?(item['contentId']) &&
                OrderItem.new(
                  content_id: item['contentId'],
                  product_id: item['productId'],
                  quantity: item['quantity'] || 0
                )
              end, variants.map(&:values))
  end

  # POST /orders
  # Creates an order, also create order_items based on the provided checkout data
  # @param address_id [Integer] The selected shipping address
  # @return comment [String] ...
  # @return items.product_id [Integer] The product
  # @return items.content_id [Integer] The version if it's a graphic
  # @return items.quantity [Integer] How many
  r.post do
    rodauth.require_authentication
    user_id = rodauth.logged_in?

    if Order.where(idempotency_key: request[:idempotencyKey]).all.count.positive?
      response.status = CONSTANTS::HTTP::CONFLICT
      return {
        type: 'duplicate_order',
        message: 'duplicate_order_message'
      }
    end

    # set shipping address id, depending on the fields in the request either from db or directly from the request
    shipping_address_id = nil
    if request[:shippingAddress]['id'].nil?
      fields = request[:shippingAddress]
      shipping_address_id = Address.create(
        is_invoice_addr: false,
        street: fields['street'],
        house_number: fields['house_number'],
        company_name: fields['company_name'],
        first_name: fields['first_name'],
        last_name: fields['last_name'],
        additional: fields['additional'],
        city: fields['city'],
        zip: fields['zip'],
        state: fields['state'],
        country: fields['country'],
        user_id: user_id
      ).id
    else
      shipping_address_id = request[:shippingAddress]['id']
      raise UnknownAddressError unless Address[shipping_address_id]
    end

    invoice_address_id = nil
    if request[:invoiceAddress].nil? # no talk about the invoice address, so it is the same as shipping
      invoice_address_id = shipping_address_id
    elsif request[:invoiceAddress]['id'].nil?
      fields = request[:invoiceAddress]
      invoice_address_id = Address.create(
        is_invoice_addr: true,
        street: fields['street'],
        house_number: fields['house_number'],
        company_name: fields['company_name'],
        first_name: fields['first_name'],
        last_name: fields['last_name'],
        additional: fields['additional'],
        city: fields['city'],
        zip: fields['zip'],
        state: fields['state'],
        country: fields['country'],
        user_id: user_id
      ).id
    else
      invoice_address_id = request[:invoiceAddress]['id']
      raise UnknownAddressError unless Address[invoice_address_id]
    end

    raise EmptyOrderException unless request[:basket].count.positive?

    final_quote = get_quote request[:basket]

    order = Order.create(
      user_id: user_id,
      comment: request[:comment] || 'n/a',
      payment_method: request[:paymentMethod],
      total_gross: final_quote.gross,
      # idempotency_key: ('a'..'z').to_a.sample(32).join,
      idempotency_key: request[:idempotencyKey],
      total_net: final_quote.net,
      weight: final_quote.weight,
      test: ENV['RACK_ENV'] != 'production',
      status: CONSTANTS::ORDER_STATUS::ATTENTION_NEEDED
    )

    final_quote.order_items.each do |item|
      order.add_order_item(item)
    end

    order.add_order_item(final_quote.postage_item)

    Invoice.create(
      address_id: invoice_address_id,
      order_id: order.id
    )

    Shipment.create(
      order_id: order.id,
      address_id: shipping_address_id
    )

    # both are depending on each other for PDF generation
    # keep statement order for tests (Savon bug, see order_tests.rb)
    order.update(status: CONSTANTS::ORDER_STATUS::RECEIVED)

    order.generate_documents
    order.send_job
    order.send_order_confirmation

    response.status = CONSTANTS::HTTP::CREATED

    # end
    return order.values
  end
end
