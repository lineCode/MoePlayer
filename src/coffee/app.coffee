EventEmitter = require 'eventemitter3'
SearchBox = require './components/SearchBox'
MusicList = require './components/MusicList'
MoePlayer = require './components/MoePlayer'

eventBus = null
searchBox = null
musicList = null
moePlayer = null

initComp = ->
	eventBus = new EventEmitter()
	searchBox = new SearchBox '.searchBox-c', eventBus
	musicList = new MusicList '.musicList-c', eventBus
	moePlayer = new MoePlayer '.moePlayer-c', eventBus

	searchBox.render()
	musicList.render()
	moePlayer.render()

	eventBinding()

eventBinding = ->
	# 搜索逻辑
	eventBus.on 'SearchBox::GetSearchResult', (data) ->
		musicList && musicList.show(data)
		moePlayer && moePlayer.updateList(data)
	eventBus.on 'SearchBox::NetworkError', (err) ->
		musicList && musicList.showError()

	# 选中播放逻辑
	eventBus.on 'MusicList::PlaySong', (song) ->
		moePlayer.play song

$(document).ready initComp
