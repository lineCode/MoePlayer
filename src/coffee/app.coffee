EventEmitter = require 'eventemitter3'
SearchBox = require './components/SearchBox'
MusicList = require './components/MusicList'
MoePlayer = require './components/MoePlayer'
DetailPanel = require './components/DetailPanel'
SettingPanel = require './components/SettingPanel'
ArtistInfo = require './components/ArtistInfo'
Util = require './components/Util'
config = require '../../config'

eventBus = null
searchBox = null
musicList = null
moePlayer = null
detailPanel = null
settingPanel = null
artistInfo = null

initComp = ->
    eventBus = new EventEmitter()
    searchBox = new SearchBox '.searchBox-c', eventBus
    musicList = new MusicList '.musicList-c', eventBus
    moePlayer = new MoePlayer '.moePlayer-c', eventBus
    detailPanel = new DetailPanel '.detailPanel-c', eventBus
    settingPanel = new SettingPanel '.settingPanel-c', eventBus
    artistInfo = new ArtistInfo '.artistInfo-c', eventBus

    searchBox.render()
    musicList.render()
    moePlayer.render()
    detailPanel.render()
    settingPanel.render()
    artistInfo.render()

    # 设置版本号
    $('.app-ver').text config.release.appVer

    # 启动动画
    setTimeout ->
        $('.start-mask').fadeOut 500
    , 500

    eventBinding()

eventBinding = ->
    # 图片禁止拖动
    $('img').on 'mousedown', (e) ->
        e.preventDefault()
        return false

    # 快捷键绑定
    $('body').on 'keydown', (evt) ->
        kc = evt.keyCode
        moePlayer && moePlayer.hotKeyResponse kc
        detailPanel && detailPanel.hotKeyResponse kc

    # 搜索逻辑
    eventBus.on 'SearchBox::GetSearchResult', (data) ->
        musicList && musicList.show data.data, data.refresh
        moePlayer && moePlayer.updateList data.data.data
        detailPanel && detailPanel.shrink()
        settingPanel && settingPanel.close()
        artistInfo && artistInfo.close()
    eventBus.on 'SearchBox::ClearSearchResult', ->
        musicList && musicList.clear()
        moePlayer && moePlayer.clearList()
        detailPanel && detailPanel.shrink()
        settingPanel && settingPanel.close()
    eventBus.on 'SearchBox::NetworkError', (err) ->
        musicList && musicList.showTips()

    # 打开设置面板
    eventBus.on 'SearchBox::OpenSettingPanel', ->
        settingPanel && settingPanel.open()

    # 选择分页
    eventBus.on 'MusicList::SelectPage', (pageIndex) ->
        searchBox && searchBox.doSearch null, null, pageIndex, null, false

    # 选中播放
    eventBus.on 'MusicList::GetSongInfo', (loaderText) ->
        searchBox && searchBox.showLoader()
        moePlayer && moePlayer.stop()
        detailPanel && detailPanel.pause()
    eventBus.on 'MusicList::GetSongInfoFailed', ->
        searchBox && searchBox.hideLoader()
    eventBus.on 'MusicList::PlaySong', (song) ->
        searchBox && searchBox.hideLoader()
        moePlayer && moePlayer.play song
        detailPanel && detailPanel.show song

    # 右键搜索歌手或专辑
    eventBus.on 'MusicList::SearchArtist', (ar) ->
        searchBox and searchBox.searchArtist ar
    eventBus.on 'MusicList::SearchAlbum', (al) ->
        searchBox and searchBox.searchAlbum al

    # 下载歌曲
    eventBus.on 'MusicList::DownloadSong', (sid) ->
        detailPanel && detailPanel.updateDLingSong sid
    eventBus.on 'DetailPanel::DownloadSong', (sid) ->
        musicList && musicList.updateDLingSong sid

    # 查看歌手详情
    eventBus.on 'DetailPanel::ShowArtistInfo', (artist) ->
        artistInfo && artistInfo.show artist
    eventBus.on 'MusicList::ShowArtistInfo', (artist) ->
        artistInfo && artistInfo.show artist

    # 暂停恢复
    eventBus.on 'MoePlayer::Pause', ->
        detailPanel && detailPanel.pause()
    eventBus.on 'MoePlayer::Resume', ->
        detailPanel && detailPanel.resume() 

    # 播放异常
    eventBus.on 'MoePlayer::UrlError', () ->
        musicList && musicList.resetPlaying()
        
    # 切换歌曲
    eventBus.on 'MoePlayer::PlayPrevSong', (data) ->
        musicList && (
            musicList.getSongInfoAndPlay data.song_id, data.idx
        )
    eventBus.on 'MoePlayer::PlayNextSong', (data) ->
        musicList && (
            musicList.getSongInfoAndPlay data.song_id, data.idx
        )

    # 播放进度更新
    eventBus.on 'MoePlayer::UpdateTime', (curTime) ->
        detailPanel && detailPanel.updateLrc curTime

    # 歌曲详情
    eventBus.on 'MoePlayer::ExpandDetailPanel', ->
        detailPanel && detailPanel.expand()

    # 切换音质
    eventBus.on 'MoePlayer::SwitchQuality', (song) ->
        searchBox && searchBox.hideLoader()
        moePlayer && moePlayer.play song
        detailPanel && detailPanel.show song

$(document).ready initComp
