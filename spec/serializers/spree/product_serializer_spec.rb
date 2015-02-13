describe Spree::Api::ProductSerializer do
  let(:product) { create(:product) }
  it "serializes a product" do
    serializer = Spree::Api::ProductSerializer.new product
    serializer.to_json.should match product.name
  end
end