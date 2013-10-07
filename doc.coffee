###
======================================================================
Helper Library (new module?):
======================================================================
###

_ = require 'underscore'

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
    template = """
    <div class="page-header" id="<%= base.replace('/','') %>">
      <h1><%= name %> <small><%= base %></small></h1>
    </div>
    <div class="row">
      <div class="span4">
        <ul class="">
          <%= toc %>
        </ul>
      </div>
      <div class="span8 offset">
        <%= p_introduction %>
      </div>
    </div>
    <%= docObjects_html %>
    <%= routes_html %>
    """
    toc_template = """
    <li>
      <a href="#<%= route.hash %>"><%= route.description %></a>
    </li>
    """
    docObject_template = """
      <h2 id="<%= docObject.hash %>">
        <%= docObject.name %>
      </h2>
      <% if (docObject.description != null && docObject.description.length > 0) { %>
      <p class="lead"><%= docObject.description %></p>
      <% } %>
      <table class="table table-striped table-condensed">
        <thead>
          <tr>
            <th class="span2">Name</th>
            <th>Description</th>
            <th class="span2">Type</th>
          </tr>
        </thead>
        <tbody>
        <% _.each(docObject.fields, function (field) { %>
          <tr>
            <td><%= field.name %> <% if (field.readonly == true) { %><span class="label label-info">readonly</span><% } %></td>
            <td><%= field.description %> <% if (field.example) { %><code><%= field.example %></code><% } %></td>
            <td><%= typeLink(field) %></td>
          </tr>
        <% }); %>
        </tbody>
      </table>
    """
    route_template = """
      <h2 id="<%= route.hash %>"><%= route.description %></h2>
      <div class="well well-small">
        <strong class="text-info"><%= route.method %> <%= route.path %></strong>
      </div>
      <% if (route.parameters != null) { %>
        <h3 class="muted">Parameters</h3>
        <div>
          <dl class="dl-horizontal">
          <% _.each(route.parameters, function(param) { %>
            <dt>
              <strong><%= param.name %></strong>
            </dt>
            <dd><% if (param.example) { %><code><%= param.example %></code><br/><% } %>
              <% if (param.default) { %>Default: <span class='label label-info'><%= param.default %></span><br/><% } %>
              <% if (param.warning) { %><span class='label label-info'><strong>warning:</strong> <%= param.warning %></span><br/><% } %>
              <%= param.description %>
            </dd>
          <% }); %>
          </dl>
        </div>
      <% } %>
      <% if (route.inputs != null) { %>
        <h3 class="muted">Inputs</h3>
        <div>
          <dl class="dl-horizontal">
          <% _.each(route.inputs, function(input) { %>
            <dt>
              <strong><%= input.name %></strong>
            </dt>
            <dd>
              <%= typeLink(input) %>
            </dd>
          <% }); %>
          </dl>
        </div>
      <% } %>
      <% if (route.responses != null) { %>
        <h3 class="muted">Responses</h3>
        <div>
          <dl class="dl-horizontal">
          <% _.each(route.responses, function(resp) { %>
            <dt>
              <strong><%= resp.status %></strong>
            </dt>
            <dd>
              <%= resp.description %>
              <% if (resp.examples != null) { _.each(resp.examples, function(example){ %>
                <p>
                <code class="text-info"><%= example.request %></code>
                <pre class="pre-scrollable"><%= JSON.stringify(example.response, null, 2) %></pre>
                </p>
              <% }) } %>
            </dd>
          <% }); %>
          </dl>
        </div>
      <% } %>
    """
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
    template = """
      <!DOCTYPE HTML>
      <html>
      <head>
        <meta charset="utf-8" />
        <title>My API</title>
        <link rel="stylesheet" href="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.2.2/css/bootstrap-combined.min.css" />
        <style> .page-header { padding-top: 60px; } </style>
      </head>
      <body data-spy="scroll">
        <div class="navbar navbar-fixed-top" id="navbar">
          <div class="navbar-inner">
            <div class="container">
              <span class="brand">
                My API
              </span>
              <ul class="nav">
                <% _.each(namespace_names, function(ns){ %>
                <li><a href="#<%= ns.id %>"><%= ns.name %></a></li>
                <% }); %>
              </ul>
            </div>
          </div>
        </div>
        <div class="container">
          <%= namespaces %>
        </div>
        <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
        <script src="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.2.2/js/bootstrap.min.js"></script>
        <script> $('#navbar').scrollspy(); </script>
      </body>
      </html>"""
    render = _.template template
    render
      namespace_names: (@_namespaces.map (namespace) -> return {name: namespace.name, id: namespace.base.replace('/','')})
      namespaces: (@_namespaces.map (namespace) -> namespace.toHTML()).join('\n')

module.exports = Doc