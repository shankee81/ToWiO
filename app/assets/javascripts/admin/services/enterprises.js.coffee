angular.module("ofn.admin").factory 'Enterprises', (my_enterprises, all_enterprises) ->
  new class Enterprises
    constructor: ->
      @my_enterprises = my_enterprises
      @all_enterprises = all_enterprises

    find: (id) ->
      enterprises = (enterprise for enterprise in @all_enterprises when enterprise.id == id)
      if enterprises.length == 0 then null else enterprises[0]
