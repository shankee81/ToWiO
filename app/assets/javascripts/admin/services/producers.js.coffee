angular.module("ofn.admin").factory "Producers", (producers, $filter) ->
  new class Producers
    constructor: ->
      @producers = producers
