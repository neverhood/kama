# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$.kama.recipients =
    init: ->

        if $.kama.action == 'index'
            formAttributePrefix = '#recipient'

            $recipients    = $('table#recipients tbody')
            $formToggler   = $('a#new-recipient-form-toggler')
            $formContainer = $('div#new-recipient-form-container')
            $form          = $('form#recipient')
            destroySelector          = 'a.destroy-recipient'

            # Destroy
            $recipients.on 'ajax:beforeSend', destroySelector, ->
                $(this).parents('tr').remove()

            # New
            $formToggler.bind 'click', (event) ->
                event.preventDefault()

                $formContainer.slideToggle 'fast'
                $formToggler.toggleClass 'active'

            # Create
            $form.bind('ajax:complete', (event, xhr, status) ->
                response = $.parseJSON xhr.responseText

                if status == 'success'
                    $form.trigger 'reset' # clear form
                    $formContainer.slideUp 'fast'
                    $formToggler.removeClass 'active'

                    $recipients.prepend response.recipient
                else
                    for own attribute, errors of response.errors
                        $formControl = $("#{formAttributePrefix}_#{attribute}")
                        $formControl.parents("div.#{$.kama.formControls.formGroup}").addClass $.kama.formControls.errorClass

                        for error in errors
                            do ->
                                $formControl.after "<span class='#{$.kama.formControls.helpBlock}'> #{error} </span>"
            ).bind('ajax:beforeSend', ->
                $form.find("span.#{$.kama.formControls.helpBlock}").remove()
                $form.find("div.#{$.kama.formControls.formGroup}").removeClass $.kama.formControls.errorClass
            )

