EventEmitter = require 'eventemitter3'
SearchBox = require './components/SearchBox'
MusicList = require './components/MusicList'
MoePlayer = require './components/MoePlayer'
Util = require './components/Util'

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

	setTimeout ->
		$('.loading-mask').fadeOut 500
	, 500

	eventBinding()

eventBinding = ->
	# 快捷键绑定
	$('body').on 'keydown', (evt) ->
		kc = evt.keyCode
		moePlayer && moePlayer.hotKeyResponse kc

	# 搜索逻辑
	eventBus.on 'SearchBox::GetSearchResult', (data) ->
		musicList && musicList.show data.data, data.refresh
		moePlayer && moePlayer.updateList data.data.data
	eventBus.on 'SearchBox::ClearSearchResult', ->
		musicList && musicList.clear()
		moePlayer && moePlayer.clearList()
	eventBus.on 'SearchBox::NetworkError', (err) ->
		musicList && musicList.showTips()

	# 选择分页
	eventBus.on 'MusicList::SelectPage', (pageIndex) ->
		searchBox && searchBox.doSearch null, pageIndex

	# 选中播放
	eventBus.on 'MusicList::PlaySong', (song) ->
		moePlayer.play song

	# 切换歌曲
	eventBus.on 'MoePlayer::PlayPrevSong', (data) ->
		musicList && (
			musicList.getSongInfoAndPlay data.song_id, data.idx
		)
	eventBus.on 'MoePlayer::PlayNextSong', (data) ->
		musicList && (
			musicList.getSongInfoAndPlay data.song_id, data.idx
		)

$(document).ready initComp
