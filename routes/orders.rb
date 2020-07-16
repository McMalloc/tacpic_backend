require 'mail'

Tacpic.hash_branch 'orders' do |r|

  # GET /orders/:id
  r.get Integer do |id|
    rodauth.require_authentication
    user_id = rodauth.logged_in?
    if User[user_id][:role] == 3 or Orders[id][:user_id] == user_id
      Orders[id].values
    else
      response.status = 403 # Forbidden
      response.write "not authorized" # TODO systematic error messages
      request.halt
    end
  end

  def get_quote(items)
    content_ids = items.map { |item| item['contentId'] }
    Quote.new(items.map { |item|
      OrderItem.new(
          content_id: item['contentId'],
          product_id: item['productId'],
          quantity: item['quantity']
      )
    }, Variant
           .where(id: content_ids) # .order_by(Sequel.lit("array_position(array#{content_ids.to_s}, id)")) # order result like the requested content_ids
           .all
           .map(&:values))
  end

  # POST /orders/quote
  r.is "quote" do
    r.post do
      if request[:items].count == 0
        return {
            items: [], packaging_item: {}, postage_item: {},
            vat: 0,
            vat_reduced: 0,
            net_total: 0,
            gross_total: 0
        }
      end
      quote = get_quote request[:items]
      {
          items: quote.order_items.map(&:values),
          packaging_item: quote.packaging_item.values,
          postage_item: quote.postage_item.values,
          vat: quote.vat,
          weight: quote.weight,
          vat_reduced: quote.reduced_vat,
          net_total: quote.net,
          gross_total: quote.gross
      }
    end
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

    begin
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
      end
    rescue
      response.status = 400
      return "invalid shipping address"
    end

    begin
      invoice_address_id = nil
      if request[:invoiceAddress].nil?
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
      end
    rescue
      response.status = 400
      return "invalid invoice address"
    end

    if request[:basket].count == 0
      response.status = 400
      return "empty order"
    end

    final_quote = get_quote request[:basket]

    order = Order.create(
        user_id: user_id,
        comment: "TODO",
        payment_method: request[:paymentMethod],
        total_gross: final_quote.gross,
        total_net: final_quote.net,
        weight: final_quote.weight,
        test: ENV['RACK_ENV'] != 'production'
    )

    invoice = Invoice.create(
        address_id: invoice_address_id,
        order_id: order.id
    )

    shipment = Shipment.create(
        order_id: order.id,
        address_id: shipping_address_id
    )

    # TODO Zahlung anlegen
    # payment = Payment.create(
    #     order_id: order.id,
    #     address_id: shipping_address_id
    # )

    final_quote.order_items.each do |item|
      order.add_order_item(item)
    end

    order.add_order_item(final_quote.postage_item)
    order.add_order_item(final_quote.packaging_item)

    voucher_invoice = nil
    voucher_shipping = Internetmarke::Voucher.new(final_quote.postage_item[:content_id], shipment.id, Address[shipping_address_id].values)
    # voucher_shipping.checkout
    shipment.update(
        voucher_id: voucher_shipping.shop_order_id,
        voucher_filename: voucher_shipping.file_name
    )

    if shipping_address_id != invoice_address_id
      voucher_invoice = Internetmarke::Voucher.new(1, shipment.id, Address[invoice_address_id].values)
      # voucher_invoice.checkout
      invoice.update(
          voucher_id: voucher_invoice.shop_order_id,
          voucher_filename: voucher_invoice.file_name
      )
    end

    invoice.generate_invoice_pdf

    # mail = Mail.new do
    #   from 'localhost'
    #   to 'robert@tacpic.de'
    #   subject 'Here is the image you wanted'
    #   body 'testest'
    # end
    #
    # mail.delivery_method :sendmail
    # mail.deliver!

    response.status = 201
    {
        order: order.values,
        quote: final_quote
    }

    # rescue StandardError => e
    #   puts e.message
    #   puts e.backtrace.inspect
    # end
  end
end