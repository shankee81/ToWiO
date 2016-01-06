# Copied from Spree (admin/admin.js.erb) and converted to coffeescript
# CHANGELOG
# 6-1-2016: Send distributor id

$(document).ready ->
  if $("#customer_search").length > 0
    $("#customer_search").select2
      placeholder: Spree.translations.choose_a_customer
      ajax:
        url: Spree.routes.user_search
        datatype: "json"
        data: (term, page) ->
          distributor_id = $("#distributor-id").data("distributor-id")
          q: term
          distributor_id: distributor_id

        results: (data, page) ->
          results: data

      dropdownCssClass: "customer_search"
      formatResult: formatCustomerResult
      formatSelection: (customer) ->
        _.each [ "bill_address", "ship_address" ], (address) ->
          data = customer[address]
          address_parts = [ "firstname", "lastname", "company", "address1", "address2", "city", "zipcode", "phone" ]
          attribute_wrapper = "#order_" + address + "_attributes_"
          unless data is `undefined`
            _.each address_parts, (part) ->
              $(attribute_wrapper + part).val data[part]

            $(attribute_wrapper + "state_id").select2 "val", data["state_id"]
            $(attribute_wrapper + "country_id").select2 "val", data["country_id"]
          else
            _.each address_parts, (part) ->
              $(attribute_wrapper + part).val ""

            $(attribute_wrapper + "state_id").select2 "val", ""
            $(attribute_wrapper + "country_id").select2 "val", ""

        $("#order_email").val customer.email
        $("#user_id").val customer.id
        $("#guest_checkout_true").prop "checked", false
        $("#guest_checkout_false").prop "checked", true
        $("#guest_checkout_false").prop "disabled", false
        customer.email
