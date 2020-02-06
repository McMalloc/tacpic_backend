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

  # POST /orders
  # Creates an order, also create order_items based on the provided checkout data
  # @param address_id [Integer] The selected shipping address
  # @return comment [String] ...
  # @return items.product_id [Integer] The product
  # @return items.content_id [Integer] The version if it's a graphic
  # @return items.quantity [Integer] How many
  r.post do
    rodauth.require_authentication
    @request = JSON.parse r.body.read
    user_id = rodauth.logged_in?

    @order = Order.create(
        address_id: @request['address_id'].to_i, # TODO Versand oder Rechnung?
        user_id: user_id,
        status: 0,
        comment: @request['comment']
    )

    @order_items = []
    @request['items'].each do |item|
      @order_items.push @order.add_order_item(
          product_id: item['product_id'],
          content_id: item['content_id'], # version_id for graphics
          status: 0,
          quantity: item['quantity'],
          base_price: 0 # TODO
      )
    end

    {
        order: @order.values,
        items: @order_items.map &:values
    }
  end
end

