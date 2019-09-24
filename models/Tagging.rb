class Tagging < Sequel::Model
  many_to_one :variant
  many_to_one :tag
  many_to_one :user

  # gets most frequently used tags for all variants, sorted descending
  # [[:freq, :tag_id], ...]
  # TODO: tags used for graphics with many variants are counted more often. get unique tags per graphic
  def self.frequency
    arr = self.all.map{ |t| t[:tag_id] }
    arr.uniq.map { |x| [arr.count(x), x] }.sort.reverse
  end
end