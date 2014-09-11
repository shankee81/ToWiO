describe "Producers service", ->
  Producers = null
  Enterprises = null
  producer = {id: 123, name: "Producer", taggable_enterprise_ids: [7]}
  enterprise = {id: 7, name: "Tagged enterprise"}

  beforeEach ->
    module "ofn.admin"
    module ($provide) ->
      $provide.value "producers", [producer]
      $provide.value "my_enterprises", []
      $provide.value "all_enterprises", [producer, enterprise]
      null

  beforeEach inject (_Producers_, _Enterprises_) ->
    Producers = _Producers_
    Enterprises = _Enterprises_


  describe "dereferencing taggable enterprises", ->
    it "dereferences on construction", ->
      expect(producer.taggable_enterprises).toEqual [enterprise]
