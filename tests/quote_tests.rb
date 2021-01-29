require_relative "./test_helper"

return
describe "Quote" do
  it "should correctly calculate a quote for a single a4 graphic" do
    post "orders/quote", {items: [{
                                      contentId: $variant_1_id,
                                      productId: "graphic",
                                      quantity: 1
                                  }]}
    response = JSON.parse(last_response.body)
    assert_equal 389 + 200, response['gross_total']
  end
  it "should correctly calculate a quote for a single a3 graphic" do
    post "orders/quote", {items: [{
                                      contentId: $variant_2_id,
                                      productId: "graphic",
                                      quantity: 1
                                  }]}
    response = JSON.parse(last_response.body)
    assert_equal 689 + 200, response['gross_total']
  end

  it "should correctly calculate a quote for a single a4 braille page" do
    post "orders/quote", {items: [{
                                      contentId: $variant_3_id,
                                      productId: "graphic",
                                      quantity: 1
                                  }]}
    response = JSON.parse(last_response.body)
    assert_equal 159 + 200, response['gross_total']
  end

  it "should correctly calculate a quote for mixed a4 graphic and braille pages" do
    post "orders/quote", {items: [{
                                      contentId: $variant_4_id,
                                      productId: "graphic",
                                      quantity: 1
                                  }]}
    response = JSON.parse(last_response.body)
    assert_equal 1099 + 200, response['gross_total']
  end

  it "should correctly calculate a quote for mixed a3 graphic and braille pages" do
    post "orders/quote", {items: [{
                                      contentId: $variant_5_id,
                                      productId: "graphic",
                                      quantity: 1
                                  }]}
    response = JSON.parse(last_response.body)
    assert_equal 869 + 200, response['gross_total']
  end

  it "should correctly calculate a quote for lots of graphic a4 pages" do
    post "orders/quote", {items: [{
                                      contentId: $variant_6_id,
                                      productId: "graphic",
                                      quantity: 6
                                  }]}
    response = JSON.parse(last_response.body)
    assert_equal (100 + 5 * 290) * 6 + 200, response['gross_total']
  end

  it "should correctly calculate a quote for lots of graphic a3 pages" do
    post "orders/quote", {items: [{
                                      contentId: $variant_7_id,
                                      productId: "graphic",
                                      quantity: 6
                                  }]}
    response = JSON.parse(last_response.body)
    assert_equal 17799 + 200, response['gross_total']
  end

  it "should correctly calculate a quote for lots of braille pages" do
    post "orders/quote", {items: [{
                                      contentId: $variant_8_id,
                                      productId: "graphic",
                                      quantity: 6
                                  }]}
    response = JSON.parse(last_response.body)
    assert_equal 1899 + 200 + 600, response['gross_total']
  end

  it "should correctly calculate a quote for lots of braille pages in one document" do
    post "orders/quote", {items: [{
                                      contentId: $variant_9_id,
                                      productId: "graphic",
                                      quantity: 1
                                  }]}
    response = JSON.parse(last_response.body)
    assert_equal 1900 + 200, response['gross_total']
  end
end

