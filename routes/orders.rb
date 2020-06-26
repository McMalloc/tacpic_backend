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
    content_ids = items.map {|item| item['contentId']}
    Quote.new(items.map{ |item|
      OrderItem.new(
          content_id: item['contentId'],
          product_id: item['productId'],
          quantity: item['quantity']
      )
    }, Variant
           .where(id: content_ids)
           .order_by(Sequel.lit("array_position(array#{content_ids.to_s}, id)")) # order result like the requested content_ids
           .all
           .map(&:values))
  end

  # POST /orders/quote
  r.on "quote" do
    r.post do
      quote = get_quote request[:items]

      {
          items: quote.order_items.map(&:values),
          packaging_item: quote.packaging_item.values,
          postage_item: quote.postage_item.values,
          vat: quote.vat,
          vat_reduced: quote.reduced_vat,
          net_total: quote.net,
          gross_total: quote.gross
      }
    end
  end

  # TODO Lieferschein generieren
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

    # Werte zusammenrechnen
    # Datensätze mit unbearbeitetem Status ablegen
    # Internetmarke bestellen
    # Bezahlung annehmen
    # Bestellung an Diakonie schicken

    begin
      if request[:items].count != 0
        order = Order.create(
            address_id: request[:address_id].to_i,
            user_id: user_id,
            status: 0,
            comment: request[:comment]
        )

        invoice = Invoice.create(
            order_id: order.id,
            address_id: request[:invoice_address_id].nil? ? nil : request[:invoice_address_id].to_i
        )

        mail = Mail.new do
          from     'localhost'
          to       'robert@tacpic.de'
          subject  'Here is the image you wanted'
          body     'testest'
        end

        mail.delivery_method :sendmail
        mail.deliver!

        order.finalise

        response.status = 201

        {
            order: order.values,
            items: order.order_items.map(&:values)
        }
      else
        response.status = 409
        response.body = "409_EMPTY_ORDER"
      end

    rescue StandardError => e
      puts e.message
      puts e.backtrace.inspect
    end
  end
end

