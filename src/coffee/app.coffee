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
		musicList && musicList.show data.data, data.refresh
		moePlayer && moePlayer.updateList(data)
	eventBus.on 'SearchBox::ClearSearchResult', ->
		musicList && musicList.clear()
	eventBus.on 'SearchBox::NetworkError', (err) ->
		musicList && musicList.showTips()

	# 选择分页
	eventBus.on 'MusicList::SelectPage', (pageIndex) ->
		searchBox && searchBox.doSearch null, pageIndex

	# 选中播放逻辑
	eventBus.on 'MusicList::PlaySong', (song) ->
		moePlayer.play song

$(document).ready initComp
