##
# 歌曲详情面板组件
# @Author VenDream
# @Update 2017-1-16 18:04:51
##

BaseComp = require './BaseComp'
Util = require './Util'
LrcPanel = require './LrcPanel'
ipcRenderer = window.require('electron').ipcRenderer
config = require '../../../config'

class DetailPanel extends BaseComp
    constructor: (selector, eventBus) ->
        super selector, eventBus

        @CUR_SONG = null
        @IS_EXPAND = false
        @DLING_SONGS = []

        @LRC_PANEL = null

    init: ->
        @bgCover = @html.querySelector '.bgCover'
        @panel = @html.querySelector '.detailPanel'

        @shrinkBtn = @html.querySelector '.shrinkBtn'

        @cover = @html.querySelector '.cover'
        @dlSongBtn = @html.querySelector '.dlSongBtn'
        @dlCoverBtn = @html.querySelector '.dlCoverBtn'
        
        @name = @html.querySelector '.name'
        @quality = @html.querySelector '.quality'
        @album = @html.querySelector '.album'
        @artist = @html.querySelector '.artist'
        @source = @html.querySelector '.source'

        @defaultCover = 'assets/default_cover.jpg'

        # 下载响应
        ipcRenderer.on 'ipcMain::DownloadSongSuccess', (event, s) =>
            if @CUR_SONG and s.song_id is @CUR_SONG.song_id
                @updateDLedSong s.song_id
            else
                Util.removeFromArr @DLING_SONGS, s.song_id

        ipcRenderer.on 'ipcMain::DownloadSongFailed', (event, s) =>
            @updateDefault s.song_id

        ipcRenderer.on 'ipcMain::DownloadCoverSuccess', (event, s) =>
            $(@dlCoverBtn).removeClass 'DLing'
                .addClass 'DLed'
                .text '封面已下载'               

        @eventBinding()

    render: ->
        htmls = 
            """
            <div class="bgCover"></div>
            <div class="detailPanel">
                <div class="shrinkBtn"></div>
                <div class="panel-left">
                    <div class="panel-c">
                        <div class="cover">
                            <img src="" alt="COVER" class="not-select">
                        </div>
                        <div class="operation">
                            <div class="button not-select dlSongBtn">
                                下载歌曲
                            </div>
                            <div class="button not-select dlCoverBtn">
                                下载封面
                            </div>
                        </div>
                    </div>
                </div>
                <div class="panel-right">
                    <div class="panel-c">
                        <div class="info">
                            <div>
                                <div class="name"></div>
                                <div class="quality"></div>
                            </div>
                            <div>
                                <div class="album">
                                    <span>专辑: </span>
                                    <span class="text"></span>
                                </div>
                                <div class="artist">
                                    <span>歌手: </span>
                                    <span class="text"></span>
                                </div>
                                <div class="source">
                                    <span>专辑: </span>
                                    <span class="text"></span>
                                </div>
                            </div>
                        </div>
                        <div class="lyric-c"></div>
                    </div>
                </div>
            </div>
            """

        @html.innerHTML = htmls
        @emit 'renderFinished'

    eventBinding: ->
        # 点击缩小按钮
        $(@shrinkBtn).unbind().on 'click', (evt) =>
            @shrink()

        # 点击下载歌曲
        $(@dlSongBtn).unbind().on 'click', (evt) =>
            hasDLed = $(@dlSongBtn).hasClass 'DLed'
            isDLing = $(@dlSongBtn).hasClass 'DLing'

            @CUR_SONG && !hasDLed && !isDLing && (
                @updateDLingSong @CUR_SONG.song_id
                @eventBus.emit 'DetailPanel::DownloadSong', @CUR_SONG.song_id
                ipcRenderer.send 'ipcRenderer::DownloadSong', @CUR_SONG
            )

        # 点击下载封面
        $(@dlCoverBtn).unbind().on 'click', (evt) =>
            hasDLed = $(@dlCoverBtn).hasClass 'DLed'
            isDLing = $(@dlCoverBtn).hasClass 'DLing'

            @CUR_SONG && !hasDLed && !isDLing && (
                @CUR_SONG.song_album = Util.filterFileName @CUR_SONG.song_album
                $(@dlCoverBtn).addClass 'DLing'
                    .text '下载中...'
                ipcRenderer.send 'ipcRenderer::DownloadCover', @CUR_SONG
            )

        # 查看歌手信息
        $(@artist).find('.text').unbind().on 'click', (evt) =>
            if not @CUR_SONG
                return false

            artist = @CUR_SONG.song_artist
            @eventBus.emit 'DetailPanel::ShowArtistInfo', artist

    #---------------------------------------------------
    #                     对外接口
    #---------------------------------------------------
    
    # 缩小详情面板
    shrink: ->
        @IS_EXPAND = false
        $(@panel).parent('.detailPanel-c').removeClass 'expand'

    # 放大详情面板
    expand: ->
        @IS_EXPAND = true
        @CUR_SONG && $(@panel).parent('.detailPanel-c').addClass 'expand'

    # 显示歌曲详情
    # @param {object} song 歌曲对象
    show: (song) ->
        @resume()
        @CUR_SONG = song.song_info
        s = song.song_info

        # 显示封面
        $(@cover).addClass 'loading'
        $img = $(@cover).find('img')
        $img.attr 'src', s.song_cover or @defaultCover
        $img[0].onload = =>
            $(@bgCover).css {
                'backgroundImage': "url(#{s.song_cover})"
            }
            $(@cover).removeClass 'rotate'
                .removeClass 'loading'

            setTimeout =>
                $(@cover).addClass 'rotate'
            , 50

        # 功能按钮
        songPath = "#{config.save_path}/#{s.song_artist}/[#{s.song_id}] #{s.song_artist} - #{s.song_name}.mp3"
        coverPath = "#{config.save_path}/专辑封面/#{s.song_album}.jpg"
        isDLing = Util.checkInArr @DLING_SONGS, s.song_id
        hasSongDLed = Util.checkDLed songPath
        hasCoverDLed = Util.checkDLed coverPath

        # 歌曲
        if isDLing is true
            @updateDLingSong s.song_id, false
        else if hasSongDLed is true
            @updateDLedSong s.song_id, false
        else
            @updateDefault()

        # 封面
        if hasCoverDLed is true
            $(@dlCoverBtn).addClass 'DLed'
                .text '封面已下载'
        else
            $(@dlCoverBtn).removeClass 'DLed'
                .text '下载封面'

        # 信息面板
        $(@name).text s.song_name
        $(@name).attr 'title', s.song_name
        $(@quality).text "#{s.song_quality}K"
        $(@album).find('.text').text s.song_album or '-'
        $(@artist).find('.text').text s.song_artist or '-'
        $(@source).find('.text').text song.source or '-'

        $(@panel).find('.text').map (i, node) ->
            $(node).attr 'title', $(node).text()

        switch s.song_quality
            when 320
                c = 'high'
            when 192, 128
                c = 'medium'
            when 96, 48
                c = 'low'
        $(@quality).attr 'class',  "quality #{c}"

        # 歌词面板
        if not @LRC_PANEL?
            @LRC_PANEL = new LrcPanel '.lyric-c', @eventBus
            @LRC_PANEL.render()

        @LRC_PANEL.loadLrc s.song_lyric

    # 恢复默认
    updateDefault: ->
        $(@dlSongBtn).attr 'class', 'button not-select dlSongBtn'
            .text '下载歌曲'

    # 更新正在下载的歌曲状态
    # @param {string}  sid    歌曲ID
    # @param {boolean} update 是否更新数组
    updateDLingSong: (sid, update = true) ->
        update && @DLING_SONGS.push sid

        $(@dlSongBtn).addClass 'DLing'
            .text '下载中...'

    # 更新已下载的歌曲状态
    # @param {string} sid 歌曲ID
    # @param {boolean} update 是否更新数组
    updateDLedSong: (sid, update = true) ->
        update && Util.removeFromArr @DLING_SONGS, sid

        $(@dlSongBtn).removeClass 'DLing'
            .addClass 'DLed'
            .text '歌曲已下载'

    # 更新歌词滚动
    # @param {number} curTime 正在播放的时间点
    updateLrc: (curTime) ->
        @LRC_PANEL.play curTime

    # 暂停封面转动
    pause: ->
        $(@cover).addClass 'animation-paused'

    # 恢复封面转动
    resume: ->
        $(@cover).removeClass 'animation-paused'

    # 快捷键响应
    # @param {number} kc 键码
    hotKeyResponse: (kc) ->
        switch kc
            # Esc键切换面板状态
            when 27
                if @IS_EXPAND is true
                    @shrink()
                else
                    @expand()

module.exports = DetailPanel
