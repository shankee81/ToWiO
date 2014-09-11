angular.module("ofn.admin").factory "Producers", (producers, Enterprises) ->
  new class Producers
    constructor: ->
      @producers = producers
      @dereferenceProducers()

    dereferenceProducers: ->
      for producer in @producers
        if producer.taggable_enterprise_ids?
          producer.taggable_enterprises =
            for id in producer.taggable_enterprise_ids
              Enterprises.find(id)
