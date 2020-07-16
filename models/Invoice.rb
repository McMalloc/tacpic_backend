require 'prawn'
require "prawn/table"
require "prawn/measurement_extensions"

class Invoice < Sequel::Model
  one_to_one :address
  many_to_many :order_items, join_table: :invoice_items
  one_to_many :payments
  one_to_one :order

  # def after_create
  #   super
  #   self.generate_invoice_pdf
  # end

  def before_save
    now = Time.now
    self.invoice_number = "RE-TS#{now.year}-#{now.month}-#{now.day}-2#{Invoice.all.count.to_s.rjust(5, "0")}"
  end

  def generate_invoice_pdf
    order = Order[self.order_id]
    user = order.user
    items = order.order_items
    payment_method = order.payment_method
    logo_path = "#{ENV['APPLICATION_BASE']}/tacpic_backend/assets/tacpic_logo.png"
    shipment = Shipment.find(order_id: self.order_id)
    shipment_adress = Address[shipment.id]
    invoice_address = nil
    invoice_number = self.invoice_number
    invoice_date = self.created_at
    due_date = Helper.add_working_days(self.created_at, 14)
    shipment_date = Helper.add_working_days(self.created_at, 3)
    voucher_path = nil

    if self.address_id.nil?
      invoice_address = shipment_adress
      voucher_path = "#{ENV['APPLICATION_BASE']}/tacpic_backend/files/vouchers/voucher_1_A0027A5C6800000001DB/0.png"
      # voucher_path = "#{ENV['APPLICATION_BASE']}/tacpic_backend/files/vouchers/#{shipment.voucher_filename}/0.png"
    else
      invoice_address = Address[self.address_id]
      voucher_path = "#{ENV['APPLICATION_BASE']}/tacpic_backend/files/vouchers/voucher_1_A0027A5C6800000001DB/0.png"
      # voucher_path = self.voucher_filename
    end

    item_table_data = [
        ["Pos.", "Stck.", "Art.-Nr.", "Netto p. Stck.", "Artikel", "Netto", "USt.-Satz"]
    ]
    items.each_with_index do |item, index|
      item_table_data.push(
          [
              index + 1,
              item.quantity,
              "#{item.product_id == 'graphic' ? 'GB' : 'GN'}-#{item.content_id.to_s.rjust(5, '0')}",
              Helper.format_currency(item.net_price / item.quantity),
              item.description,
              Helper.format_currency(item.net_price),
              '7%' #todo lookup for product_id
          ]
      )
    end

    total_table_data = []

    total_table_data.push([
                             '', '', '', '', 'Zwischensumme netto',
                             Helper.format_currency(order.total_net),
                             '' #todo lookup for product_id
                         ])

    total_table_data.push([
                             '', '', '', '', 'zzgl. Umsatzsteuer',
                             Helper.format_currency(order.total_gross - order.total_net),
                             '' #todo lookup for product_id
                         ])

    total_table_data.push([
                             '', '', '', '', 'Gesamt brutto',
                             Helper.format_currency(order.total_gross),
                             '' #todo lookup for product_id
                         ])

    Prawn::Document.generate("#{ENV['APPLICATION_BASE']}/tacpic_backend/files/invoices/#{self.invoice_number}.pdf",
                             page_size: 'A4', page_layout: :portrait, left_margin: 20.mm, margin_right: 20.mm, top_margin: 10.mm, bottom_margin: 10.mm) do
      font_families.update(
          "Roboto" => {
              normal: "#{ENV['APPLICATION_BASE']}/tacpic_backend/public/webfonts/Roboto/Roboto-Regular.ttf",
              bold: "#{ENV['APPLICATION_BASE']}/tacpic_backend/public/webfonts/Roboto/Roboto-Bold.ttf",
              black: "#{ENV['APPLICATION_BASE']}/tacpic_backend/public/webfonts/Roboto/Roboto-Black.ttf"
          }
      )
      font "Roboto", size: 10
      second_column_offset = 110.mm
      first_column_offset = 0.mm
      customer_info_position = (297 - 100).mm
      footer_height = 25.mm
      width_percentile = bounds.width / 100.0
      column_widths = [width_percentile*7, width_percentile*7, width_percentile*10, width_percentile*10, width_percentile*41, width_percentile*15, width_percentile*10]
      #                Posten                Menge                Art.-Nr.             Stückpreis           Artikel              Nettopreis           USt.-Satz"]


      text "RECHNUNG", size: 24, style: :black
      image logo_path, at: [second_column_offset - 5.mm, (297 - 20).mm], width: 75.mm
      image voucher_path, at: [first_column_offset, (297 - 45).mm], width: 80.mm

      bounding_box([second_column_offset, (297 - 50).mm], :width => 60.mm, :height => 100.mm) do
        text "Anschrift", style: :bold
        text "tacpic UG (haftungsbeschränkt)"
        text "Breitscheidstr. 51"
        text "39114 Magdeburg"
        move_down 10.mm
        text "Kontakt", style: :bold
        text "Telefonnummer: (+49) 176 4348 6710"
        text "E-Mail-Adresse: kontakt@tacpic.de"
        text "Webseite: tacpic.de"
      end

      bounding_box([first_column_offset, customer_info_position], :width => 60.mm) do
        text "Rechnungsadresse", style: :bold
        text invoice_address.company_name
        text invoice_address.first_name + ' ' + invoice_address.last_name
        text invoice_address.street + ' ' + invoice_address.house_number
        text invoice_address.zip + ' ' + invoice_address.city
        text invoice_address.country
      end

      bounding_box([second_column_offset, customer_info_position], width: 60.mm) do
        text "Ihre Kundennr.:", style: :bold
        text "Rechnungsnr.:"
        text "Rechnungsdatum:"
        text "Bestellnummer:"
        text "Lieferdatum:"
      end

      bounding_box([second_column_offset + 30.mm, customer_info_position], width: 60.mm) do
        text user.id.to_s.rjust(4, '0'), style: :bold
        text invoice_number
        text invoice_date.strftime("%d.%m.%Y")
        text order.id.to_s.rjust(4, '0')
        text shipment_date.strftime("%d.%m.%Y")
      end

      move_down 15.mm
      text "Rechnung #{invoice_number}", style: :bold, size: 12
      text "Vereinbarungsgemäß berechnen wir unsere Leistungen wie folgt: "
      move_down 3.mm

      table item_table_data,
            header: true,
            column_widths: column_widths,
            row_colors: ['ffffff', 'efefef'] do
        columns([3,5,6]).align = :right
        # columns([0, 1,3,5,6]).valign = :center
        cells.padding = 3
        cells.valign = :center
        cells.borders = [:top, :left, :right]
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

      move_down 3.mm
      if order.payment_method == 'invoice'
        text "Bitte überweisen Sie den Gesamtbetrag bis zum <b>#{due_date.strftime("%d.%m.%Y")}</b> auf das am Dokumentenende aufgeführte Konto.",
             inline_format: true
      end
      if order.payment_method == 'paypal'
        text "Ihre Rechnung wurde bereits via PayPal überwiesen."
      end
      # end
      # end


      # repeat(:all) do
      text_box "<b>Bankverbindung</b>\nPostbank\nIBAN: DE 6910 0100 1009 3662 5102\nBIC: PBNKDEFF",
               at: [0, footer_height], width: 65.mm, height: footer_height, valign: :bottom, inline_format: true

      text_box "\nUSt-IdNr.: DE328130974\nAmtsgericht Stendal, HRB 27976\nGeschäftsführende: Laura Evers, Robert Wlcek, Florentin Förschler",
               at: [70.mm, footer_height], width: 90.mm, height: footer_height, valign: :bottom

      number_pages "Seite <b><page> von <total></b>", at: [0, 0], width: bounds.width, align: :right, inline_format: true
      # end


    end
  end
end
