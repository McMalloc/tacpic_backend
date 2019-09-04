require_relative "./test_helper"

describe "my example spec" do
  it "should successfully return a greeting" do
    get '/'
    last_response.body.must_include 'Hallo'
  end
end
