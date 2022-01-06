Tacpic.hash_branch :internal, 'orders' do |r|
  r.is do
    r.get do
      Order.all.map(&:values)
    end
  end

  r.on Integer do |id|
    r.get do
      {
        order: Order[id].values,
        order_items: OrderItem
          .where(order_id: id, product_id: ['graphic_nobraille', 'graphic'])
          .join(:variants, id: :content_id)
          .map(&:values),
        shipments: Order[id].shipments.map(&:values),
        invoices: Order[id].invoices.map(&:values),
        payments: Order[id].invoices.map { |invoice| invoice.payments.map(&:values) },
        user: {
          user: Order[id].user.values,
          addresses: Order[id].user.addresses.map(&:values)
        }
      }
    end

    r.post 'rpc' do
      case request[:method]
        when 'correct_invoice'
          Invoice[request[:invoice_id]].update(status: CONSTANTS::INVOICE_STATUS::REPLACED) unless Order[id].invoices
          Invoice.create(
            order_id: id,
            status: CONSTANTS::INVOICE_STATUS::CREDIT_NOTE,
            address_id: Invoice[request[:invoice_id]].address_id
          ).generate_invoice_pdf
          return 'ok'
        when 'cancel_invoice'
          if Order[id].invoices.empty?
            response.status = CONSTANTS::HTTP::NOT_ACCEPTABLE
            return 'error: order has no invoices'
          end
          Invoice[request[:invoice_id]].update(status: CONSTANTS::INVOICE_STATUS::CANCELLED) unless Order[id].invoices.empty?
          Invoice[request[:invoice_id]].generate_invoice_pdf
          return 'ok'
        when 'purchase_invoice_voucher'
          Invoice[request[:invoice_id]].get_voucher force_checkout: true, ppl_id: 1
          Invoice[request[:invoice_id]].generate_invoice_pdf
          return 'ok'
        when 'resend_order_confirmation'
          Order[id].send_order_confirmation
          return 'ok'
        when 'resend_production_job'
          job = Job.new(Order[id])
          job.send_mail
          return 'ok'
        when 'regenerate_documents'
          generate_documents
        else
          response.status = CONSTANTS::HTTP::BAD_REQUEST
          return {
            type: 'unknown_method',
            message: 'unknown_method_message'
          }
      end
    end
  end
end
