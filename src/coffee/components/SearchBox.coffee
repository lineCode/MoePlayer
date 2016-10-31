##
# 搜索框组件
# @Author VenDream
# @Update 2016-10-31 16:06:15
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

        @LOADING_TEXT = {
            DEFAULT: '努力加载中...ORZ'
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
        @loaderText = @html.querySelector '.loader-text'
        @loaderShape = @html.querySelector '.loader-shape'
        @settingBtn = @html.querySelector '.setting-btn'
        @minBtn = @html.querySelector '.min-btn'
        @closeBtn = @html.querySelector '.close-btn'

        @hideLoader()
        @eventBinding()

    render: ->
        htmls = 
            """
            <div class="searchBox">
                <select class="source" title="音乐库">
                    <option data-src="qq">QQ音乐(推荐)</option>
                    <option data-src="netease">网易云音乐</option>
                    <option data-src="xiami">虾米音乐</option>
                    <option data-src="kuwo">酷我音乐</option>
                </select>
                <select class="stype" disabled title="搜索类型">
                    <option data-type="single">单曲</option>
                    <option data-type="artist">歌手</option>
                    <option data-type="album">专辑</option>
                </select>
                <input name="music-info" type="text" class="search-input" 
                    placeholder="输入关键词（名称、歌手、专辑）" />
                <div class="go-btn not-select" title="搜索">搜索</div>
                <div class="clear-btn not-select" title="清空">清空</div>
                <div class="loader not-select">
                    <div class="loader-shape">
                        <div class="bubble bubble1"></div>
                        <div class="bubble bubble2"></div>
                        <div class="bubble bubble3"></div>
                    </div>
                    <div class="loader-text"></div>
                </div>
                <div class="divider not-select"></div>
                <div class="setting-btn not-select" title="设置"></div>
                <div class="min-btn not-select" title="最小化"></div>
                <div class="close-btn not-select" title="关闭"></div>
            </div>
            """

        @html.innerHTML = htmls
        @emit 'renderFinished'

    eventBinding: ->
        $(@goBtn).attr 'data-searching', '0'

        # 切换音乐库
        $(@source).on 'change', (evt) =>
            sn = $(evt.target).val()
            tx = "音乐库切换为: 『#{sn}』"
            Util.toast tx, {
                width: 25
            }

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

        # 设置
        $(@settingBtn).on 'click', (evt) =>
            @eventBus.emit 'SearchBox::OpenSettingPanel'

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

        @hideLoader()
    
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

        switch stype
            when 'single', 'artist'
                api = @API.SINGLE
            when 'album'
                api = @API.ALBUM
            else
                return false

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
                if refresh is true
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
        @toggleType 'artist'
        $(@input).val ar
        @doSearch ar, @src, 1, 'artist'

    # 搜索专辑
    # @param {string} al 专辑
    searchAlbum: (al) ->
        @toggleType 'album'
        $(@input).val al.split('#')[0]
        @doSearch al.split('#')[1], @src, 1, 'album'

    # 展示loader
    # @param {string} msg loading文本
    showLoader: (msg = @LOADING_TEXT.DEFAULT) ->
        $(@loaderText).text msg
        $(@loader).fadeIn 0

    # 隐藏loader
    hideLoader: ->
        $(@loader).fadeOut 0

    # 清空搜索结果
    clear: ->
        @sstr = ''
        @page = 1
        $(@input).val ''
        @toggleType 'single'
        @eventBus.emit 'SearchBox::ClearSearchResult'

module.exports = SearchBox
