describe "Enterprises service", ->
  Enterprises = null
  enterprise = {id: 7, name: "Enterprise"}

  beforeEach ->
    module "ofn.admin"
    module ($provide) ->
      $provide.value "my_enterprises", []
      $provide.value "all_enterprises", [enterprise]
      null

  beforeEach inject (_Enterprises_) ->
    Enterprises = _Enterprises_

  describe "finding enterprises by id", ->
    it "returns the enterprise", ->
      expect(Enterprises.find(7)).toEqual enterprise

    it "returns null when not found", ->
      expect(Enterprises.find(123)).toBeNull()
