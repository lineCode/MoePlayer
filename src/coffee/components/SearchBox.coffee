##
# 搜索框组件
# @Author VenDream
# @Update 2016-8-25 11:49:10
##

BaseComp = require './BaseComp'
Util = require './Util'
config = require '../../../config.js'
electron = window.require 'electron'
ipcRenderer = electron.ipcRenderer

class SearchBox extends BaseComp
    constructor: (selector, eventBus) ->
        super selector, eventBus

        @TIPS = {
            RETRY: '请求失败了，尝试重新请求...0v0'
        }

        @API = {
            SINGLE: "#{config.host}:#{config.port}/api/music/single",
            ALBUM: "#{config.host}:#{config.port}/api/music/album",
        }

    init: ->
        @sstr = ''
        @page = 1
        @src = 'netease'
        @type = 'single'

        @source = @html.querySelector '.source'
        @stype = @html.querySelector '.stype'
        @input = @html.querySelector '.search-input'
        @goBtn = @html.querySelector '.go-btn'
        @clearBtn = @html.querySelector '.clear-btn'
        @loader = @html.querySelector '.loader'
        @minBtn = @html.querySelector '.min-btn'
        @closeBtn = @html.querySelector '.close-btn'

        $(@loader).fadeOut 0
        @eventBinding()

    render: ->
        htmls = 
            """
            <div class="searchBox">
                <select class="source" title="音乐库">
                    <option data-src="netease">网易云音乐</option>
                    <option data-src="kuwo">酷我音乐</option>
                </select>
                <select class="stype" disabled title="搜索类型">
                    <option data-type="single">单曲</option>
                    <option data-type="album">专辑</option>
                </select>
                <input name="music-info" type="text" class="search-input" 
                    placeholder="输入歌曲信息（名称、歌手）" />
                <div class="go-btn not-select" title="搜索">搜索</div>
                <div class="clear-btn not-select" title="清空">清空</div>
                <div class="loader"></div>
                <div class="divider not-select"></div>
                <div class="min-btn not-select" title="最小化"></div>
                <div class="close-btn not-select" title="关闭"></div>
            </div>
            """

        @html.innerHTML = htmls
        @emit 'renderFinished'

    eventBinding: ->
        $(@goBtn).attr 'data-searching', '0'

        # 搜索
        $(@goBtn).on 'click', (evt) =>
            @toggleType 'single'
            sstr = $(@input).val()
            src = $(@source).find('option:selected').attr 'data-src'
            stype = $(@stype).find('option:selected').attr 'data-type'

            if sstr isnt '' and $(@goBtn).attr('data-searching') is '0'
                @doSearch sstr, src, 1, stype

        # 清空
        $(@clearBtn).on 'click', (evt) =>
            @clear()

        # 最小化
        $(@minBtn).on 'click', (evt) =>
            ipcRenderer.send 'ipcRenderer::Minimize'

        # 关闭窗口
        $(@closeBtn).on 'click', (evt) =>
            ipcRenderer.send 'ipcRenderer::CloseWin'

        # Enter快捷键搜索
        $(@input).on 'keydown', (evt) =>
            evt.stopPropagation()
            kc = evt.keyCode
            if kc is 13
                $(@goBtn).trigger 'click'
    
    # 切换搜索类型
    # @param {string} type 类型
    toggleType: (type) ->
        selector = "option[data-type=\"#{type}\"]"
        $t = $(@stype).find selector

        $t.length > 0 and $(@stype).val $t.text()

    #---------------------------------------------------
    #                     对外接口
    #---------------------------------------------------

    # 普通搜索
    # @param {string}  sstr    关键词
    # @param {string}  src     音乐来源
    # @param {number}  page    页码
    # @param {string}  stype   搜索类型
    # @param {boolean} refresh 是否刷新分页
    doSearch: (sstr = @sstr, src = @src, page = @page, stype = @type, refresh = true) ->
        if sstr is ''
            return false

        api = if stype is 'single' then @API.SINGLE else @API.ALBUM

        $.ajax {
            type: 'POST',
            url: api,
            data: {
                sstr: sstr,
                src: src
                page: page,
            },
            beforeSend: =>
                $(@goBtn).attr 'data-searching', '1'
                @showLoader()
            ,
            complete: =>
                $(@goBtn).attr 'data-searching', '0'
                @hideLoader()
            success: (data) =>
                @sstr = sstr
                @src = src
                @type = stype
                @page = page
                data.data.page = @page
                data.data.src = @src
                @eventBus.emit 'SearchBox::GetSearchResult', {
                    data: data
                    refresh: refresh
                }
            ,
            error: (err) =>
                Util.showMsg @TIPS.RETRY, 3000, 3
                @eventBus.emit 'SearchBox::NetworkError', err
        }

    # 搜索歌手
    # @param {string} ar 歌手
    searchArtist: (ar) ->
        @toggleType 'single'
        $(@input).val ar
        @doSearch ar, @src, 1, 'single'

    # 搜索专辑
    # @param {string} al 专辑
    searchAlbum: (al) ->
        @toggleType 'album'
        $(@input).val al.split('#')[0]
        @doSearch al.split('#')[1], @src, 1, 'album'

    # 展示loader
    showLoader: ->
        $(@loader).fadeIn 200

    # 隐藏loader
    hideLoader: ->
        $(@loader).fadeOut 200

    # 清空搜索结果
    clear: ->
        @sstr = ''
        @page = 1
        $(@input).val ''
        @toggleType 'single'
        @eventBus.emit 'SearchBox::ClearSearchResult'

module.exports = SearchBox
