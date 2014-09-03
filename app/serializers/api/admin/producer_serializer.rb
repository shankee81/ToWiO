class Api::Admin::ProducerSerializer < ActiveModel::Serializer
  attributes :id, :name, :taggable_enterprise_ids

  def taggable_enterprise_ids
    OpenFoodNetwork::Permissions.new(scope).
      taggable_enterprises(object).
      pluck :id
  end
end
