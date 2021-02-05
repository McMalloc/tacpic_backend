FactoryBot.define do
  factory :variant do
    id { 1 }
    graphic_no_of_pages { 1 }
    graphic_format { "a4" }
    braille_no_of_pages { 0 }
    braille_format { "a4" }
  end
end
