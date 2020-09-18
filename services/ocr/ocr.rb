class OCR
  @@root = "#{ENV['APPLICATION_BASE']}/files/temp/"

  def initialize(file_name)
    @file_name = file_name
    system "tesseract #{@file_name} #{@file_name}"
  end

  def get_ocr
    File.read(@file_name + '.txt')
  end

  def save_brf(index)

  end

  def save_files

  end

  def save_thumbnails(index)

  end
end