class Shipment < Sequel::Model
  many_to_one :address
  one_to_many :shipped_items

  def get_pdf_path
    File.join(ENV['APPLICATION_BASE'], "/files/shipment_receipts/", "lieferschein_" + self.id.to_s + ".pdf")
  end

  def generate_shipping_pdf
    order = Order[self.order_id]
    user = order.user
    items = order.order_items
    logo_path = "#{ENV['APPLICATION_BASE']}/assets/tacpic_logo.png"
    invoice = Invoice.find(order_id: order.id)
    invoice_number = invoice.invoice_number
    invoice_address = Address[invoice.address_id]
    invoice_date = invoice.created_at
    shipment_date = Helper.add_working_days(self.created_at, 3) #todo no magic numbers
    voucher_path = "#{ENV['APPLICATION_BASE']}/files/vouchers/#{ENV['RACK_ENV'] == 'production' ? self.voucher_filename : 'placeholder'}/0.png"

    item_table_data = [
        ["Pos.", "Stck.", "Art.-Nr.", "Netto p. Stck.", "Artikel", "Netto", "USt.-Satz"]
    ]
    items.each_with_index do |item, index|
      art_no = ""
      if item.product_id == 'graphic'
        art_no = "GB-#{item.content_id.to_s.rjust(5, '0')}"
      end
      if item.product_id == 'graphic_nobraille'
        art_no = "GN-#{item.content_id.to_s.rjust(5, '0')}"
      end
      item_table_data.push(
          [
              index + 1,
              item.quantity,
              art_no,
              Helper.format_currency(item.net_price / item.quantity),
              item.description,
              Helper.format_currency(item.net_price),
              GraphicPriceCalculator.taxes[:de_reduced_vat].to_s + '%' #todo lookup for product_id
          ]
      )
    end

    Prawn::Document.generate("#{ENV['APPLICATION_BASE']}/files/shipment_receipts/lieferschein_#{self.id}.pdf",
                             page_size: 'A4', page_layout: :portrait, left_margin: 20.mm, margin_right: 20.mm, top_margin: 10.mm, bottom_margin: 10.mm) do
      font_families.update(
          "Roboto" => {
              normal: "#{ENV['APPLICATION_BASE']}/public/webfonts/Roboto/Roboto-Regular.ttf",
              bold: "#{ENV['APPLICATION_BASE']}/public/webfonts/Roboto/Roboto-Bold.ttf",
              black: "#{ENV['APPLICATION_BASE']}/public/webfonts/Roboto/Roboto-Black.ttf"
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


      text "LIEFERSCHEIN", size: 24, style: :black
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

      number_pages "Seite <b><page> von <total></b>", at: [0, 0], width: bounds.width, align: :right, inline_format: true
    end
  end
end
