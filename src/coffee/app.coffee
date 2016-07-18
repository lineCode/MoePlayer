EventEmitter = require 'eventemitter3'
SearchBox = require './components/SearchBox'

eventBus = null
searchBox = null

initComp = ->
	eventBus = new EventEmitter()
	searchBox = new SearchBox '.searchBox-c', eventBus

$(document).ready initComp
