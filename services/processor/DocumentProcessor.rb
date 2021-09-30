require 'erb'
require_relative '../../terminal_colors'
require 'base64'
require "rqrcode"


# TODO: Dateinamenschema templaten
class DocumentProcessor
  QR_SIZE = 12 # in mm

  @@svg_renderer = ERB.new File.read("#{ENV['APPLICATION_BASE']}/services/processor/svg_template.svg.erb")
  @@brf_renderer = ERB.new File.read("#{ENV['APPLICATION_BASE']}/services/processor/brf_template.brf.erb")
  @@font_data = Base64.strict_encode64 File.read("#{ENV['APPLICATION_BASE']}/services/processor/tacpic_swellbraille_euro6f.woff")
  @@style = File.read("#{ENV['APPLICATION_BASE']}/services/processor/style.css")
  # @@root = "#{ENV["APPLICATION_BASE"]}/files"
  @@root = "#{ENV['APPLICATION_BASE']}/files"

  def initialize(version)
    @version = version.values
    @variant = version.variant.values
    @contributors = version.variant.contributors
    @graphic = version.variant.graphic
    document = JSON.parse(version.document)
    @pages = document['pages']
    @image_description = document['braillePages']['imageDescription']
    @braille_pages = document['braillePages']
    @graphic_width, @graphic_height = Helper.determine_dimensions(@variant[:graphic_format],
                                                                  @variant[:graphic_landscape])
    @file_name = "v#{@version[:id]}-#{@graphic.title.gsub(/[^0-9A-Za-z.\-]/,
                                                          '_')}-#{@variant[:title].gsub(/[^0-9A-Za-z.\-]/,
                                                                                        '_') or 'basis'}"
  end

  def save_svg(index, qrcode)
    File.open "#{@@root}/#{@file_name}-VECTOR-p#{index}.svg", 'w' do |f|
      binding = {
        content: @pages[index]['rendering'],
        font_data: @@font_data,
        style: @@style,
        version_id: @version[:id],
        qr_code: Base64.strict_encode64(qrcode),
        qr_size: QR_SIZE,
        width: @graphic_width,
        height: @graphic_height,
        title: "#{@variant[:title]}: #{@graphic[:title]}",
        contributors: @contributors.map { |c| c[:display_name] }.join(', '),
        description: @variant[:description],
        date: @version[:created_at]
      }
      f.write @@svg_renderer.result_with_hash(binding)
    end
  end

  def save_brf(formattedContent)
    # TODO: Validierer, damit keine fehlerhaften BRFs ausgegeben werden, die die Produktion stören

    File.open "#{@@root}/#{@file_name}-BRAILLE.brf", 'w' do |f|
      page_index = 0
      binding = {
        cellsPerRow: @braille_pages['cellsPerRow'],
        height: @braille_pages['height'],
        marginLeft: @braille_pages['marginLeft'],
        marginTop: @braille_pages['marginTop'],
        pageNumbers: @braille_pages['pageNumbers'],
        rowsPerPage: @braille_pages['rowsPerPage'],
        width: @braille_pages['width'],
        braille_content: formattedContent.reduce('') do |memo, pagebreak|
          page_index += 1
          suffix = if page_index === formattedContent.count
                     ''
                   else
                     "\x0c" # page feed
                   end
          memo + pagebreak.reduce('') do |pagememo, line|
            pagememo + line + "\x0a"
          end + suffix
        end
      }
      f.write @@brf_renderer.result_with_hash(binding)
    end
  end

  def get_qrcode
    # filename = File.join(@@root, 'temp') + "/qr_#{@version[:id]}.png"
    # system "qrencode -o #{filename} \"https://tacpic.de/catalogue/#{@version[:graphic_id]}/variant/#{@version[:variant_id]}\""
    # system "convert #{filename} -colorspace gray -contrast-stretch 0 +level-colors '#0000FF,' #{filename}"
    # @qr64 = `base64 -w0 #{filename}`
    url = "https://tacpic.de/catalogue/#{@version[:graphic_id]}/variant/#{@version[:variant_id]}"
    RQRCode::QRCode.new(url).as_svg(
      color: "0000FF",
      fill: 'ffffff',
      standalone: true,
      module_size: 5,
      use_path: true
    )
  end

  def save_rtf(graphic_title, variant_title, description)
    document = RRTF::Document.new
    document.paragraph(
      'font-size' => 18,
      'space_after' => 12,
      'bold' => true
    ) << graphic_title + "\\line\nVariante: " + variant_title

    unless description['type'].length.zero?
      document.paragraph(
        'font-size' => 12,
        'space_after' => 12
      ) << '(' + description['type'] + ')\\line'
    end
    document.paragraph(
      'space_after' => 12
    ) << description['summary'] + '\\line'
    document.paragraph(
      'space_after' => 12
    ) << description['details']

    File.open "#{@@root}/#{@file_name}-RICHTEXT.rtf", 'w' do |f|
      f.write document.to_rtf
    end
  end

  def save_files
    begin
      save_brf @braille_pages['formatted']
      save_rtf @graphic.title, @variant[:title], @image_description
      @pages.nil? && return
      @pages.count.times do |index|
        save_svg index, get_qrcode
        save_pdf index
        save_thumbnails index
      end
      # TODO: wenn einer Variante Seiten entfernt werden, werden die Dateien trotzdem noch gemergt. => map
      merge_input = "#{@@root.shellescape}/#{@file_name}-PRINT-p*.pdf"
      merge_output = "#{@@root.shellescape}/#{@file_name}-PRINT-merged.pdf"
      # print system "gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=#{merge_output} #{merge_input}"
      system "gs -sProcessColorModel=DeviceCMYK -sColorConversionStrategy=CMYK -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=#{merge_output} #{merge_input}"
    rescue StandardError => e
      puts e.message
      puts e.backtrace.inspect
      return nil
    end
    @file_name
  end

  def save_thumbnails(index)
    source = "#{@@root.shellescape}/#{@file_name}-RASTER-p#{index}.png"
    dest_prefix = if ENV['RACK_ENV'] == 'test'
                    "#{@@root.shellescape}/thumbnails/#{@file_name}"
                  else
                    "#{@@root.shellescape}/../public/thumbnails/#{@file_name}"
                  end
    system "cat #{source} | pngtopnm | pnmscale 0.2 | pnmtopng > #{dest_prefix}-THUMBNAIL-sm-p#{index}.png"
    system "cat #{source} | pngtopnm | pnmscale 0.6 | pnmtopng > #{dest_prefix}-THUMBNAIL-xl-p#{index}.png"
  end

  def save_pdf(index)
    `node #{ENV['APPLICATION_BASE'].shellescape}/services/processor/convert_svg #{@file_name.to_s.shellescape} #{@variant[:graphic_format].to_s.shellescape} #{@variant[:graphic_landscape].to_s.shellescape} #{index} #{@@root}`
  end
end
