require 'victor'
include Victor

module Embosserpage
  def self.to_brf(content, top_margin, left_margin, cells_per_row, rows_per_page, page_number)
    brf = "\eDBT9,TM#{top_margin.to_s},BI#{left_margin.to_s},CH#{cells_per_row.to_s},LP#{rows_per_page.to_s},PN#{page_number.to_s};#{content}"
    brf
  end
end