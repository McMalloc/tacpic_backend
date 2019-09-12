require_relative "./test_helper"

describe "Graphic#after_save" do
  before do
    @user = User.create(
                    email: 'user@example.de'
    )
  end

  it "should create corresponding instances" do
    @graphic = Graphic.create title: "valid title for a graphic", user_id: @user.id, request: false
    @variant = Variant.where graphic_id: @graphic.id
    @version = Version.where variant_id: @variant.id

    assert_instance_of Integer, @graphic.id

    # @version = @user.add_version number: 0
    #
    # assert_instance_of Integer, @version.variant.id
    # assert_instance_of Integer, @version.variant.graphic.id
    # assert_equal 16, @version.id.length
  end
end
