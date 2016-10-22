##
# 音乐列表组件
# @Author VenDream
# @Update 2016-10-22 18:06:43
##

BaseComp = require './BaseComp'
Util = require './Util'
Paginator = require './Paginator'
config = require '../../../config'

fs = window.require 'fs'
electron = window.require 'electron'
ipcRenderer = electron.ipcRenderer
remote = electron.remote
Menu = remote.Menu
MenuItem = remote.MenuItem

class MusicList extends BaseComp
    constructor: (selector, eventBus) ->
        super selector, eventBus

        @TIPS = {
            NO_SONG: '噫，都没有歌曲可以下载0v0',
            SUGGEST: '搜索点什么听听吧ww',
            DOWNLOAD_START: '加入下载列表',
            DOWNLOAD_FAILED: '歌曲下载失败',
            DOWNLOAD_SUCCESS: '歌曲下载完成',
            NOT_FOUND_ERROR: '搜索不到相关的东西惹QAQ',
            NETWORK_ERROR: '服务器出小差啦，请重试QAQ',
            RETRY: '请求失败了，请重试QAQ',
            NO_COPYRIGHT: '该歌曲为付费版权歌曲QAQ'
        }

        @CONTEXT = {
            AR: '',
            AL: ''
        }

        @API = {
            INFO: "#{config.host}:#{config.port}/api/music/info"
        }

        @PAGINATOR = null
        @DLING_SONGS = []

    init: ->
        @src = ''
        @curSongId = ''
        @menu = null

        @table = @html.querySelector 'table'
        @tipsRow = @html.querySelector '.tips-row'

        # 下载响应
        ipcRenderer.on 'ipcMain::DownloadSongSuccess', (event, s) =>
            @updateDLedSong s.song_id
            Util.showMsg "#{@TIPS.DOWNLOAD_SUCCESS}: 《#{s.song_name}》", null, 2
        ipcRenderer.on 'ipcMain::DownloadSongFailed', (event, s) =>
            @updateDefault s.song_id
            Util.showMsg "#{@TIPS.DOWNLOAD_FAILED}: #{s.state}", null, 3

        @buildCtcMenu()
        @updatePagination 0

    render: ->
        htmls =
            """
            <div class="musicList">
                <div class="table-c">
                    <table>
                        <tr>
                            <th class="list-index"></th>
                            <th class="list-title">标题</th>
                            <th class="list-artist">歌手</th>
                            <th class="list-album">专辑</th>
                            <th class="list-duration">时长</th>
                            <th class="list-operation">操作</th>
                        </tr>
                        <tr class="tips-row">
                            <td colspan=6>#{@TIPS.SUGGEST}</td>
                        </tr>
                    </table>
                </div>
                <div class="mpc"></div>
            </div>
            """

        @html.innerHTML = htmls

        @emit 'renderFinished'

    # 事件绑定
    eventBinding: ->
        # 双击播放 && 右键选中
        $(@table).find('.song').unbind().on 'dblclick', (evt) =>
            evt.stopPropagation()
            $target = $(evt.currentTarget)
            idx = $target.attr 'data-idx'
            sid = $target.attr 'data-sid'
            sn = $target.find('.title-col').text()
            sid && @getSongInfoAndPlay sid, idx
        .on 'mousedown', (e) =>
            if e.button is 2
                $target = $(e.currentTarget)
                alid = $target.attr 'data-alid'
                @CONTEXT.AR = $target.find('.artist-col').text()
                @CONTEXT.AL = $target.find('.album-col').text() + '#' + alid

        # 下载歌曲
        $(@table).find('.dlBtn').unbind().on 'click', (evt) =>
            evt.stopPropagation()
            $song = $(evt.currentTarget).parents('.song')

            if $song.hasClass('hasDLed') is true or $song.hasClass('DLing') is true
                return false

            sn = $song.find('.title-col').text()
            sid = $song.attr 'data-sid'

            sid && @getSongInfoAndDownload sid

    # 创建右键菜单
    buildCtcMenu: ->
        # 搜索歌手
        ipcRenderer.on 'ipcMain::SearchArtist', =>
            @CONTEXT.AR and @eventBus.emit 'MusicList::SearchArtist', @CONTEXT.AR
        # 搜索专辑
        ipcRenderer.on 'ipcMain::SearchAlbum', =>
            @CONTEXT.AL and @eventBus.emit 'MusicList::SearchAlbum', @CONTEXT.AL
        # 下载全部歌曲
        ipcRenderer.on 'ipcMain::DownloadAllSongs', =>
            @downloadAllSongs()

        $(@table).on 'contextmenu', (e) =>
            e.preventDefault()
            $(@table).find('.song').length > 0 and e.target.nodeName is 'TD' and \
            ipcRenderer.send 'ipcRenderer::OpenContextMenu'

    # 歌曲信息获取不到时，使用备用歌曲信息
    # @param {object} songInfo 歌曲信息对象
    fixSongInfo: (songInfo) ->
        sid = songInfo.song_id
        $sr = $('.song[data-sid="' + sid + '"]')

        TI = $sr.find('.title-col').text().replace /[《》]/g, ''
        AL = $sr.find('.album-col').text().replace /[《》]/g, ''
        AR = $sr.find('.artist-col').text().replace /[《》]/g, ''

        !songInfo.song_name && songInfo.song_name = TI
        !songInfo.song_album && songInfo.song_album = AL
        !songInfo.song_artist && songInfo.song_artist = AR

    # 还原默认状态
    # @param {string} sid 歌曲ID
    updateDefault: (sid) ->
        $sr = $('.song[data-sid="' + sid + '"]')
        $sr.length > 0 && (
            $sr.removeClass 'hasDLed'
                .removeClass 'DLing'
        )

    # 更新显示正在播放的歌曲
    # @param {string} sid 歌曲ID
    updatePlayingSong: (sid) ->
        @curSongId = sid
        $sr = $('.song[data-sid="' + sid + '"]')
        $sr.length > 0 && (
            $('.song').removeClass 'playing'
            $sr.addClass 'playing'
        )

    # 更新正在下载的歌曲
    # @param {string} sid 歌曲ID
    updateDLingSong: (sid) ->
        @DLING_SONGS.push sid

        $sr = $('.song[data-sid="' + sid + '"]')

        $sr.length > 0 && (
            $sr.addClass 'DLing'
            $sr.find('.dlBtn').attr 'title', '下载中'
        )

    # 更新已下载的歌曲
    # @param {string} sid 歌曲ID
    updateDLedSong: (sid) ->
        Util.removeFromArr @DLING_SONGS, sid

        $sr = $('.song[data-sid="' + sid + '"]')

        $sr.length > 0 && (
            $sr.removeClass 'DLing'
                .addClass 'hasDLed'
            $sr.find('.dlBtn').attr 'title', '已下载'
        )

    # 显示错误提示信息
    # @param {string} msg 错误提示
    showTips: (msg = @TIPS.NETWORK_ERROR) ->
        # 清空原来的数据
        $(@table).find('.song').remove()

        # 显示错误信息
        $(@tipsRow).find('td').text msg
        $(@tipsRow).fadeIn 200

    # 显示搜索结果
    # @param {array}  songs 歌曲数组
    # @param {number} base  歌曲偏移基数
    showResult: (songs, base) ->
        # 清空原来的数据
        $(@table).find('.song').remove()

        # 渲染新的数据
        songs.map (s, i) =>
            filepath = "#{config.save_path}/#{s.artist_name}/[#{s.song_id}] #{s.artist_name} - #{s.song_name}.mp3"
            isDLing = Util.checkInArr @DLING_SONGS, s.song_id
            hasDLed = Util.checkDLed filepath
            idx = Util.fixZero base + i + 1, @totalCount

            if isDLing is true
                c = 'DLing'
                t = '下载中'
            else if hasDLed is true
                c = 'hasDLed'
                t = '已下载'
            else
                c = ''
                t = '点击下载'

            trHtml = 
                """
                <tr class="song not-select #{
                    if String(s.song_id) is String(@curSongId) then 'playing' else ''
                } #{c}" data-sid="#{s.song_id}" data-alid="#{s.album_id}" data-idx="#{i}">
                    <td class="index-col">#{idx}</td>
                    <td class="title-col">#{s.song_name}</td>
                    <td class="artist-col">#{s.artist_name}</td>
                    <td class="album-col">#{s.album_name}</td>
                    <td class="duration-col">#{Util.normalizeSeconds(s.duration)}</td>
                    <td class="operation-col">
                        <div class="btn dlBtn" title="#{t}"></div>
                    </td>
                </tr>
                """
            $tr = $(trHtml)

            # 设置title属性
            $tr.find('.title-col').map (i, t) ->
                $(t).attr 'title', $(@).text()
            $tr.find('.album-col').map (i, t) ->
                $(t).attr 'title', $(@).text()

            $(@table).append $tr

        @eventBinding()

    #---------------------------------------------------
    #                     对外接口
    #---------------------------------------------------

    # 渲染数据
    # @param {object}  data    数据
    # @param {boolean} refresh 是否为新的请求
    show: (data, refresh = true) ->
        $(@tipsRow).fadeOut 0

        if data and data.status is 'success'
            @src = data.data.src
            if data.data.songs
                base = (data.data.page - 1) * config.num_per_page
                @totalCount = data.data.count
                @showResult data.data.songs, base
                # 是否为新的搜索
                refresh && @updatePagination()

            if @totalCount is 0
                @showTips @TIPS.NOT_FOUND_ERROR
        else
            @showTips @TIPS.NETWORK_ERROR

    # 更新分页
    # @param {number} maxEntries 数据项总数
    updatePagination: (maxEntries = @totalCount) ->
        if not @PAGINATOR?
            @PAGINATOR = new Paginator '.mpc', @eventBus, maxEntries, {
                callback: (pageIndex, container) =>
                    @eventBus.emit 'MusicList::SelectPage', pageIndex + 1
            }
        else
            @PAGINATOR.doPagination maxEntries

    # 清空搜索结果
    clear: ->
        $(@table).find('.song').remove()

        @updatePagination 0
        @showTips @TIPS.SUGGEST

    # 重置歌曲播放状态
    resetPlaying: ->
        @curSongId = ''
        $('.song').removeClass 'playing'

    # 获取歌曲信息并播放
    # @param {string} sid        歌曲ID
    # @param {number} idx        歌曲索引
    getSongInfoAndPlay: (sid, idx, loaderText) ->
        $.ajax {
            type: 'POST',
            url: @API.INFO,
            data: {
                song_id: sid,
                src: @src
            },
            beforeSend: =>
                $('.song').removeClass 'playing'
                @eventBus.emit 'MusicList::GetSongInfo'
            ,
            success: (data) =>
                if data and data.status is 'success'
                    s = data.data.song_info
                    s.idx = idx
                    id = s.song_id
                    ar = s.song_artist
                    sn = s.song_name

                    # 若歌曲已下载，则使用本地文件进行播放
                    localpath = "#{config.save_path}/#{ar}/[#{id}] #{ar} - #{sn}.mp3"
                    if Util.checkDLed(localpath) is true
                        s.song_url = localpath

                    @fixSongInfo s
                    @updatePlayingSong sid
                    @eventBus.emit 'MusicList::PlaySong', data.data
                else
                    if data.status is 'copyright'
                        Util.showMsg @TIPS.NO_COPYRIGHT, 3000, 3
                    else
                        Util.showMsg @TIPS.NETWORK_ERROR, 3000, 3
                    @eventBus.emit 'MusicList::GetSongInfoFailed'

                    return false
            , 
            error: (err) =>
                Util.showMsg @TIPS.RETRY, 3000, 3
                @eventBus.emit 'MusicList::GetSongInfoFailed'
        }

    # 获取歌曲信息并执行下载
    # @param {string} sid 歌曲ID
    getSongInfoAndDownload: (sid) ->
        $.ajax {
            type: 'POST',
            url: @API.INFO,
            data: {
                song_id: sid,
                src: @src
            },
            success: (data) =>
                if data and data.status is 'success'
                    if $.isEmptyObject(data.data.song_info) is false
                        @updateDLingSong sid
                        @eventBus.emit 'MusicList::DownloadSong', sid
                        ipcRenderer.send 'ipcRenderer::DownloadSong', data.data.song_info
                    else
                        Util.showMsg @TIPS.NETWORK_ERROR, 3000, 3
                        @eventBus.emit 'MusicList::GetSongInfoFailed'
                        
                        return false
            , 
            error: (err) =>
                Util.showMsg @TIPS.RETRY, 3000, 3
                @eventBus.emit 'MusicList::GetSongInfoFailed'
        }

    # 下载该页全部歌曲
    downloadAllSongs: ->
        self = @
        $songs = $(@table).find('.song')

        if $songs.length > 0
            $songs.each ->
                $(@).find('.dlBtn').trigger 'click'
        else
            Util.showMsg @TIPS.NO_SONG, 3000, 3

module.exports = MusicList
