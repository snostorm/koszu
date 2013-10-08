###
======================================================================
Helper Library (new module?):
======================================================================
###

_ = require 'underscore'
fs = require 'fs'

__TEMPLATE_CACHE__ = {}
getTemplateSync = (path) ->
  unless __TEMPLATE_CACHE__[path]?
    __TEMPLATE_CACHE__[path] = fs.readFileSync "#{path}", encoding: "utf8"
  return __TEMPLATE_CACHE__[path]

convert_hash = (field) ->
  type = field.type
  unless type?.toLowerCase() in ['string', 'number', 'integer', 'boolean']
    t = field.array || type
    return ('obj' + t).replace(' ', '_').replace('/', '-')

class Route
  constructor: (@method, @path, @description) ->
    @_parameters = []
    @_responses = []
    @_inputs = []
    @
  parameter: (data) ->
    @_parameters.push data
    return @
  input: (data) ->
    _.defaults data, {type: 'String', description: ''}
    @_inputs.push data
  response: (data) ->
    @_responses.push data
    return @
  toJSON: ->
    output =
      method: @method
      path: @path
      description: @description
    output.parameters = @_parameters unless _.isEmpty @_parameters
    output.responses = @_responses unless _.isEmpty @_responses
    unless _.isEmpty @_inputs
      @_inputs.forEach (input) ->
        input.typeHash = (convert_hash input) if input.type?
      output.inputs = @_inputs
    return output

class DocObject
  constructor: (@name, @description) ->
    @_fields = []
    @
  field: (data) ->
    _.defaults data, {type: 'String', description: ''}
    @_fields.push data
    return @
  toJSON: ->
    output =
      name: @name
      description: @description
    unless _.isEmpty @_fields
      @_fields.forEach (field) =>
        field.typeHash = (convert_hash field) if field.type?
      output.fields = @_fields
    return output

class Namespace
  constructor: (@name, data) ->
    @_routes = []
    @_objects = []
    @base = data.base
    @introduction = data.introduction
    @
  object: (method, description) ->
    docObject = new DocObject method, description
    docObject.parent = @
    @_objects.push docObject
    return docObject
  route: (method, path, description) ->
    @_routes.push (route = new Route method, path, description)
    return route
  toJSON: ->
    output =
      name: @name
      base: @base
      introduction: @introduction
      docObjects: @_objects.map (docObject) =>
        docObject = JSON.parse (JSON.stringify docObject.toJSON())
        docObject.hash = ('obj' + docObject.name).replace(' ', '_').replace('/', '-')
        return docObject
      routes: @_routes.map (route) =>
        route = JSON.parse (JSON.stringify route.toJSON())
        route.path = @base + route.path
        route.hash = (route.method + @base + route.path).replace(' ', '_').replace('/', '-')
        return route
  toHTML: ->
    typeLink = (obj) ->
      if obj.typeHash
        return "<a href=\"##{obj.typeHash}\">#{obj.type}</a>"
      else
        return obj.type
    template = getTemplateSync "#{__dirname}/templates/default/_namespace.underscore.html"
    toc_template = getTemplateSync "#{__dirname}/templates/default/_toc.underscore.html"
    docObject_template = getTemplateSync "#{__dirname}/templates/default/_docObject.underscore.html"
    route_template = getTemplateSync "#{__dirname}/templates/default/_route.underscore.html"

    render = _.template template
    json_namespace = @toJSON()
    routes = json_namespace.routes
    toc_html = (_.template(toc_template, {route: r}) for r in routes).join '\n'
    docObjects_html = (_.template(docObject_template, {docObject: docObject, typeLink: typeLink}) for docObject in json_namespace.docObjects).join '\n'
    routes_html = (_.template(route_template, {route: r, typeLink: typeLink}) for r in routes).join '\n'
    p_introduction = if (introduction = json_namespace.introduction)?
      '<div class=""><p class="lead">' + introduction.replace(/\n([ \t]*\n)+/g, '</p><p>').replace('\n', '<br />') + '</p></div>'
    else
      ''
    render _.extend {routes_html: routes_html, docObjects_html: docObjects_html, p_introduction: p_introduction, toc: toc_html}, json_namespace

class Doc
  constructor: ->
    @_namespaces = []
    @
  namespace: (name, data) ->
    if name? and data?
      namespace = new Namespace name, data
      @_namespaces.push namespace
    else
      namespace = _.last @_namespaces
    return namespace
  route: ->
    namespace = @namespace()
    namespace.route.apply namespace, arguments
  toJSON: ->
    output = @_namespaces.map (namespace) ->
      namespace.toJSON()
  toHTML: ->
    template = getTemplateSync "#{__dirname}/templates/default/layout.underscore.html"
    render = _.template template
    render
      namespace_names: (@_namespaces.map (namespace) -> return {name: namespace.name, id: namespace.base.replace('/','')})
      namespaces: (@_namespaces.map (namespace) -> namespace.toHTML()).join('\n')

module.exports = Doc