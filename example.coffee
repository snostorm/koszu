doc = new (require './index')

###################
###################
### Widget API  ###
###################
###################

widgets = doc.namespace "Widgets API",
  base: '/widget'
  structure: [
    'id'
    'name'
  ]
  introduction: "The Widgets API mostly exists for the purpose of managing sprocket objects."

(widgets.object 'WidgetObject', 'The main widget object returned by the API.')
  .field
    name: 'id'
    description: 'The widget\'s UUID'
    readonly: true
  .field
    name: 'name'
    description: 'The wiget\'s human-friendly name'
  .field
    name: 'owner'
    type: 'OwnerObject'
    
(widgets.object 'OwnerObject', 'Ownership properties for a widgety resource.')
  .field
    name: 'external_id'
    description: 'External ID'
  .field
    name: 'service_id'
    description: 'OAuth Service ID'

(widgets.route 'GET', '', 'List widgets')
  .parameter
    name: 'page'
    example: '2'
    type: 'Number'
    description: 'To request certain page of documents. This also generates a Link http header if additional data is available on other pages.'
  .parameter
    name: 'per_page'
    example: '10'
    type: 'Number'
    description: 'To specify the number of documents in a page.'

(widgets.route 'POST', '', 'Adds a new widget')
  .input
    name: 'JSON'
    type: 'WidgetObject'

output = doc.toHTML()

fs = require 'fs'
fs.writeFile "#{__dirname}/example.html", output, (err) ->
  message = if err then err else "example.html has been updated."
  console.log message