require 'prawn'
require 'prawn/table'
require 'prawn/measurement_extensions'
require_relative '../services/internetmarke/internetmarke'

class Invoice < Sequel::Model
  include CommerceData
  many_to_one :address
  many_to_many :order_items, join_table: :invoice_items
  one_to_many :payments
  one_to_one :order

  def before_create
    super
    now = Time.now
    self.invoice_number = "RE-TS#{now.year}-#{now.month}-#{now.day}-2#{(Invoice.all.count + 1).to_s.rjust(5, '0')}"
  end

  def finalise
    generate_invoice_pdf
  end

  def invoice_date
    created_at + (5 * 24 * 60 * 60)
  end

  def get_voucher(force_checkout: false, ppl_id: nil)
    # if the invoice address differs, purchase a letter voucher and generate separate shipping receipt
    raise UnknownAddressError if address_id.nil?

    if voucher_filename.nil? || force_checkout
      ppl_id = ppl_id || Shipment.find(order_id: order_id).address_id != address_id ? 1 : Order[order_id].get_postage_item.content_id

      voucher = Internetmarke::Voucher.new(
        ppl_id,
        id,
        address.values
      )

      voucher.checkout

      if voucher.error.nil?
        update(
          voucher_id: voucher.voucher_id,
          voucher_filename: voucher.file_name
        )
        InternetmarkeTransaction.create(
          invoice_id: id,
          shop_order_id: voucher.shop_order_id,
          voucher_id: voucher.voucher_id,
          balance: voucher.wallet_balance,
          ppl_id: voucher.product,
          amount: voucher.total
        )
        File.join(ENV['APPLICATION_BASE'], '/files/vouchers/', voucher_filename, '0.png')
      else
        raise voucher.error
      end
    else
      File.join(ENV['APPLICATION_BASE'], '/files/vouchers/', voucher_filename, '0.png')
    end
  end

  def get_pdf_path
    File.join(ENV['APPLICATION_BASE'], "/files/invoices/#{invoice_number}.pdf")
  end

  def get_item_listing
    listing = []
    Order[order_id].order_items.each_with_index do |item, index|
      art_no = ''
      art_no = "GB-\u00AD#{item.content_id.to_s.rjust(5, '0')}" if item.product_id == 'graphic'
      art_no = "GN-\u00AD#{item.content_id.to_s.rjust(5, '0')}" if item.product_id == 'graphic_nobraille'
      listing.push(
        [
          index + 1,
          item.quantity,
          art_no,
          Helper.format_currency(item.net_price),
          item.description,
          Helper.format_currency(item.net_price * item.quantity),
          get_taxrate(
            !get_product(item.product_id).nil? && get_product(item.product_id)[:reduced_vat] ? :de_reduced_vat : :de_vat
          ).to_s + '%' # TODO: lookup for product_id
        ]
      )
    end
    listing
  end

  def generate_invoice_pdf
    order = Order[order_id]
    user = order.user
    payment_method = order.payment_method
    logo_path = File.join ENV['APPLICATION_BASE'], '/assets/tacpic_logo.png'
    shipment = Shipment.find(order_id: order_id)
    shipment_address = Address[shipment.address_id]
    invoice_number = self.invoice_number
    invoice_address = Address[address_id]
    # due_date = Helper.add_working_days(self.created_at, 20)
    shipment_date = Helper.add_working_days(created_at, 3) # TODO: Zeiten zentraler speichern
    invoice_date = self.invoice_date
    status = self.status

    voucher_path = if status == CONSTANTS::INVOICE_STATUS::CANCELLED
                     voucher_filename.nil? ? nil : get_voucher
                   else
                     get_voucher
                   end

    item_table_data = [
      ['Pos.', 'Stck.', 'Art.-Nr.', 'Netto p. Stck.', 'Artikel', 'Netto', 'USt.-Satz']
    ]
    item_table_data.concat(get_item_listing)

    total_table_data = []

    total_table_data.push([
                            '', '', '', '', 'Zwischensumme netto',
                            Helper.format_currency(order.total_net),
                            '' # TODO: lookup for product_id
                          ])

    total_table_data.push([
                            '', '', '', '', 'zzgl. Umsatzsteuer',
                            Helper.format_currency(order.total_gross - order.total_net),
                            '' # TODO: lookup for product_id
                          ])

    total_table_data.push([
                            '', '', '', '', 'Gesamt brutto',
                            Helper.format_currency(order.total_gross),
                            '' # TODO: lookup for product_id
                          ])

    Prawn::Document.generate("#{ENV['APPLICATION_BASE']}/files/invoices/#{self.invoice_number}.pdf",
                             page_size: 'A4', page_layout: :portrait, left_margin: 20.mm, margin_right: 20.mm, top_margin: 10.mm, bottom_margin: 10.mm) do
      font_families.update(
        'Roboto' => {
          normal: "#{ENV['APPLICATION_BASE']}/assets/Roboto-Regular.ttf",
          bold: "#{ENV['APPLICATION_BASE']}/assets/Roboto-Bold.ttf",
          black: "#{ENV['APPLICATION_BASE']}/assets/Roboto-Black.ttf"
        }
      )
      font 'Roboto', size: 10
      second_column_offset = 110.mm
      first_column_offset = 0.mm
      customer_info_position = (297 - 100).mm
      footer_height = 25.mm
      width_percentile = bounds.width / 100.0
      column_widths = [width_percentile * 7, width_percentile * 7, width_percentile * 10, width_percentile * 10,
                       width_percentile * 41, width_percentile * 15, width_percentile * 10]
      #                Posten                Menge                Art.-Nr.             Stückpreis           Artikel              Nettopreis           USt.-Satz"]

      text 'RECHNUNG', size: 24, style: :black
      image logo_path, at: [second_column_offset - 5.mm, (297 - 20).mm], width: 75.mm
      image voucher_path, at: [first_column_offset, (297 - 45).mm], width: 80.mm unless voucher_path.nil?

      bounding_box([second_column_offset, (297 - 50).mm], width: 60.mm, height: 100.mm) do
        text 'Anschrift', style: :bold
        text 'tacpic UG (haftungsbeschränkt) i. L.'
        text 'Breitscheidstr. 51'
        text '39114 Magdeburg'
        move_down 10.mm
        text 'Kontakt', style: :bold
        text 'Telefonnummer: (+49) 176 4348 6710'
        text 'E-Mail-Adresse: kontakt@tacpic.de'
        text 'Webseite: tacpic.de'
      end

      bounding_box([first_column_offset, customer_info_position], width: 60.mm) do
        text 'Rechnungsadresse', style: :bold
        text invoice_address.company_name
        text invoice_address.first_name + ' ' + invoice_address.last_name
        text invoice_address.street + ' ' + invoice_address.house_number
        text invoice_address.zip + ' ' + invoice_address.city
        text invoice_address.country
      end

      bounding_box([second_column_offset, customer_info_position], width: 60.mm) do
        text 'Ihre Kunden-Nr.:', style: :bold
        text 'Rechnungs-Nr.:'
        text 'Rechnungsdatum:'
        text 'Bestellnummer:'
        text 'Lieferdatum:'
      end

      if invoice_address.id != shipment.address_id && !shipment_address.nil?
        bounding_box([second_column_offset / 2, customer_info_position], width: 60.mm) do
          text 'Lieferadresse', style: :bold
          text shipment_address.company_name
          text shipment_address.first_name + ' ' + shipment_address.last_name
          text shipment_address.street + ' ' + shipment_address.house_number
          text shipment_address.zip + ' ' + shipment_address.city
          text shipment_address.country
        end
      end

      bounding_box([second_column_offset + 30.mm, customer_info_position], width: 60.mm) do
        text user.id.to_s.rjust(4, '0'), style: :bold
        text invoice_number
        text invoice_date.strftime('%d.%m.%Y')
        text order.id.to_s.rjust(4, '0')
        text shipment_date.strftime('%d.%m.%Y')
      end

      move_down 15.mm
      if status == CONSTANTS::INVOICE_STATUS::CREDIT_NOTE
        text "Rechnungsgutschrift #{invoice_number}", style: :bold, size: 12
      else
        text "Rechnung #{invoice_number}", style: :bold, size: 12
      end
      text 'Vereinbarungsgemäß berechnen wir unsere Leistungen wie folgt: '
      move_down 3.mm

      table item_table_data,
            header: true,
            column_widths: column_widths,
            row_colors: %w[ffffff efefef] do
        columns([3, 5, 6]).align = :right
        # columns([0, 1,3,5,6]).valign = :center
        cells.padding = 3
        cells.valign = :center
        cells.borders = %i[top left right]
        cells.border_width = 1
        cells.border_color = 'eeeeee'
        row(0).borders = [:bottom]
        row(0).valign = :bottom
        row(0).align = :left
        row(0).font_style = :bold
        row(0).background_color = 'efefef'
      end

      table total_table_data, column_widths: column_widths do
        cells.padding = 3
        cells.align = :right
        cells.valign = :center
        cells.borders = []

        row(-2).column(4).color = 'cccccc'
        row(-1).column(4).color = 'cccccc'
        row(-1).font_style = :bold
        row(-1).size = 12
        row(-1).borders = [:top]
        row(-1).border_width = 1
      end

      if status == CONSTANTS::INVOICE_STATUS::CANCELLED
        move_up 200.mm
        rotate 30
        fill_color 'ff0000'
        transparent(0.5, 0.75) do
          draw_text 'storniert', at: [100, 0], size: 80
        end
        restore_graphics_state
        move_down 200.mm
      end

      move_down 3.mm
      if order.payment_method == 'invoice' && status != CONSTANTS::INVOICE_STATUS::CREDIT_NOTE
        text 'Die Zahlung des Gesamtbetrag ist <b>20 Tage nach Rechnungsdatum fällig</b>. Bitte überweisen Sie ihn auf das am Dokumentenende aufgeführte Konto. Geben Sie dabei bitte die <b>Rechnungsnummer als Verwendungszweck</b> an.',
             inline_format: true
      end
      text 'Ihre Rechnung wurde bereits via PayPal überwiesen.' if order.payment_method == 'paypal'
      # end
      # end

      # repeat(:all) do
      text_box "<b>Bankverbindung</b>\nPostbank\nIBAN: DE69 1001 0010 0936 6251 02\nBIC: PBNKDEFF",
               at: [0, footer_height], width: 65.mm, height: footer_height, valign: :bottom, inline_format: true

      text_box "\nUSt-IdNr.: DE328130974 | St.-Nr.: 102/117/03623\nAmtsgericht Stendal, HRB 27976\nGeschäftsführende: Robert Wlcek, Florentin Förschler",
               at: [70.mm, footer_height], width: 90.mm, height: footer_height, valign: :bottom

      number_pages 'Seite <b><page> von <total></b>', at: [0, 0], width: bounds.width, align: :right,
                                                      inline_format: true
      # end
    end
  end
end
