Tacpic.hash_branch 'orders' do |r|
  # GET /orders/:id/finalise?hash=xyz
  r.get Integer, 'finalise' do |id|
    if Order[id].get_hash == request['hash']
      Order[id].update(status: 2)
      SMTP::SendMail.instance.send_invoice_to_accounting(Order[id].invoice)
      return 'Produktionsauftrag bestaetigt.'
    else
      response.status = 406
      return '406: Ungültiger Hash. Bitte Link überprüfen'
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
    if (User[user_id][:role] == 3) || (Orders[id][:user_id] == user_id)
      Orders[id].values
    else
      response.status = 403 # Forbidden
      response.write 'not authorized' # TODO: systematic error messages
      request.halt
    end
  end

  def get_quote(items)
    content_ids = items.map { |item| item['contentId'] }
    Quote.new(items.map do |item|
      OrderItem.new(
        content_id: item['contentId'],
        product_id: item['productId'],
        quantity: item['quantity']
      )
    end, Variant
      .where(id: content_ids) # .order_by(Sequel.lit("array_position(array#{content_ids.to_s}, id)")) # order result like the requested content_ids
      .all
      .map(&:values))
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
      response.status = 409
      return 'duplicate order'
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
      comment: 'TODO',
      payment_method: request[:paymentMethod],
      total_gross: final_quote.gross,
      idempotency_key: request[:idempotencyKey],
      total_net: final_quote.net,
      weight: final_quote.weight,
      test: ENV['RACK_ENV'] != 'production'
    )

    final_quote.order_items.each do |item|
      order.add_order_item(item)
    end

    order.add_order_item(final_quote.postage_item)
    # order.add_order_item(final_quote.packaging_item)

    invoice = Invoice.create(
      address_id: invoice_address_id,
      order_id: order.id
    )

    shipment = Shipment.create(
      order_id: order.id,
      address_id: shipping_address_id
    )

    # TODO: Zahlung anlegen
    # the shipping voucher will be put on the invoice if it's the same address
    # begin
    voucher_shipping = Internetmarke::Voucher.new(
      final_quote.postage_item[:content_id],
      order.id,
      Address[shipping_address_id].values
    )
    # may not be checked out, but neccessary for error inspection
    voucher_invoice = Internetmarke::Voucher.new(
        1,
        order.id,
        Address[invoice_address_id].values
      )

    order.update(status: 1)
    voucher_shipping.checkout

    unless voucher_shipping.error
      shipment.update(
        voucher_id: voucher_shipping.shop_order_id,
        voucher_filename: voucher_shipping.file_name
      )
    end

    # if the invoice address differs, purchase a letter voucher and generate separate shipping receipt
    if shipping_address_id != invoice_address_id
      voucher_invoice.checkout

      unless voucher_invoice.error
        invoice.update(
          voucher_id: voucher_invoice.shop_order_id,
          voucher_filename: voucher_invoice.file_name
        )
      end
      unless voucher_shipping.error
        shipment.generate_shipping_pdf
      end
    end

    unless voucher_shipping.error || voucher_invoice.error
      invoice.generate_invoice_pdf
      job = Job.new(order)
      job.send_mail
      order.update(status: 2)
    end

    SMTP::SendMail.instance.send_order_confirmation(
      User[user_id].email,
      invoice
    )

    response.status = 201
    return order.values
    # end
  end
end
