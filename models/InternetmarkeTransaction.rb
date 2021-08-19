class InternetmarkeTransaction < Sequel::Model
  def create_report
    current_balance = balance
    invoice_number = Invoice[invoice_id].invoice_number
    relevant_shipment_id = shipment_id
    datev_info_file = "#{ENV['APPLICATION_BASE']}/files/internetmarke_balance_#{current_balance}_#{Time.now.to_i}.pdf"
    Prawn::Document.generate(datev_info_file,
                             page_size: 'A4', page_layout: :portrait,
                             left_margin: 20.mm, margin_right: 20.mm, top_margin: 10.mm, bottom_margin: 10.mm) do
      bounding_box([10.mm, (297 - 20).mm], width: 180.mm, height: 100.mm) do
        text 'Stand der Portokasse'
        move_down 10.mm
        text "#{Helper.format_currency(current_balance)}", style: :bold
        move_down 10.mm
        text "vom #{Time.now}"
        text "Nach Kauf der Marke für Lieferung #{relevant_shipment_id} mit Rechnung #{invoice_number}"
      end
    end

    return datev_info_file
  end

  def after_create
    super
    if balance < 2000
      SMTP::SendMail.instance.send_info(
        'Kontostand der Portokasse knapp',
        "Stand mit Transaktions-ID #{id}: #{Helper.format_currency(balance)}",
        create_report
      )
    end
  end

  def get_voucher
    File.join(ENV['APPLICATION_BASE'], 'files/vouchers', "voucher_#{voucher_id}", '0.png')
  end
end
