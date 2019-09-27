module Helper
  def self.table_print(rows)
    rows.first.keys.each { |key| print trunc(key.to_s, 8) + "\t" }
    print "\n"
    rows.each do |row|
      row.each { |v| print trunc(v[1].to_s, 8) + "\t" }
      print "\n"
    end
    rows.first.keys.each { |key| print trunc(key.to_s, 8) + "\t" }
  end

  def self.trunc(string, length)
    if string.length <= length
      return string
    end
    string.to_s[0..length-3] + "…"
  end
end