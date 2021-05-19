require 'zip'
require 'uuid'

def linebreak(text)
  text.scan(/.{17}|.+/).join("\x0A") # todo magic number ersetzen
end

def append_frontmatter(braille_pages, current_file_name, order_id)
  braille_pages + "\x0C\x1B\xFC#{linebreak current_file_name}\x0A\x0ABESTELL-ID: #{order_id}\x1B\xFC"
end

class Job
  @@root = "#{ENV['APPLICATION_BASE']}/files/jobs/"
  # @@fm_renderer = ERB.new File.read("#{ENV['APPLICATION_BASE']}/services/processor/brf_frontmatter_template.brf.erb")
  attr_accessor :zipfile_name

  def initialize(order)
    uuid_gen = UUID.new
    uuid = uuid_gen.generate
    @order = order
    @zipfile_name = File.join(@@root, order.id.to_s + "-" +  uuid + ".zip");
    Zip::File.open(@zipfile_name, Zip::File::CREATE) do |zipfile|
      order.order_items.each do |order_item|
        if order_item.product_id != 'graphic' && order_item.product_id != 'graphic_nobraille'
          break;
        end
        variant = Variant[order_item.content_id]
        graphic_file = variant.current_file_name + '-PRINT-merged.pdf'
        zipfile.add(graphic_file, File.join(ENV['APPLICATION_BASE'], "files", graphic_file))
        # also pack the braille pages
        if order_item.product_id == 'graphic'
          braille_file = variant.current_file_name + '-BRAILLE.brf'
          braille_contents = File.open(File.join(ENV['APPLICATION_BASE'], 'files', braille_file)).read

          tempfile = Tempfile.new('FM_' + braille_file)
          tempfile.write append_frontmatter(braille_contents, variant.current_file_name, order.id)
          tempfile.close
          zipfile.add(braille_file, tempfile.path)
        end
      end

      zipfile.add("Rechnung.pdf", order.invoice.get_pdf_path)
      shipment = Shipment.find order_id: order.id
      #TODO eventuell gibt es mehrere Lieferungen pro Bestellung. Abfangen
      if File.exists? shipment.get_pdf_path
        zipfile.add("Lieferschein.pdf", shipment.get_pdf_path)
      end
    end
  end

  def send_mail
    SMTP::SendMail.instance.send_production_job(
        @order,
        @zipfile_name
    )
  end
end