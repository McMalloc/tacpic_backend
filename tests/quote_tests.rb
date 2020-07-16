require_relative "./test_helper"

describe "Quote" do
  it "should correctly calculate a quote" do
    post "orders/quote", {items: [{
        contentId: $variant_a_id,
        productId: "graphic",
        quantity: 1
    }]}
    response = JSON.parse(last_response.body)
    assert_equal 510, response['gross_total']

    post "orders/quote", {items: [{
        contentId: $variant_b_id,
        productId: "graphic",
        quantity: 1
    }]}
    response = JSON.parse(last_response.body)
    assert_equal response['gross_total'], 827

    post "orders/quote", {items: [{
        contentId: $variant_c_id,
        productId: "graphic",
        quantity: 1
    }]}
    response = JSON.parse(last_response.body)
    assert_equal response['gross_total'], 287

    post "orders/quote", {items: [{
        contentId: $variant_d_id,
        productId: "graphic",
        quantity: 1
    }]}
    response = JSON.parse(last_response.body)
    assert_equal response['gross_total'], 602

    post "orders/quote", {items: [{
        contentId: $variant_e_id,
        productId: "graphic",
        quantity: 1
    }]}
    response = JSON.parse(last_response.body)
    assert_equal response['gross_total'], 1140

    post "orders/quote", {items: [{
        contentId: $variant_f_id,
        productId: "graphic",
        quantity: 1
    }]}
    response = JSON.parse(last_response.body)
    assert_equal response['gross_total'], 1579

    post "orders/quote", {items: [{
        contentId: $variant_g_id,
        productId: "graphic",
        quantity: 1
    }]}
    response = JSON.parse(last_response.body)
    assert_equal response['gross_total'], 9787

    post "orders/quote", {items: [{
        contentId: $variant_h_id,
        productId: "graphic",
        quantity: 1
    }]}
    response = JSON.parse(last_response.body)
    assert_equal response['gross_total'], 1485

    post "orders/quote", {items: [{
        contentId: $variant_j_id,
        productId: "graphic",
        quantity: 1
    }]}
    response = JSON.parse(last_response.body)
    assert_equal response['gross_total'], 2180

  end
end

