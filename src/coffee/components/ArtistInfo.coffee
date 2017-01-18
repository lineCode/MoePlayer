##
# Artist Info Component
# @Author VenDream
# @Update 2017-1-18 15:11:38
##

BaseComp = require './BaseComp'
Util = require './Util'

config = require '../../../config'

class ArtistInfo extends BaseComp
    constructor: (selector, eventBus) ->
        super selector, eventBus

        @initAttr()

    init: () ->
        @NODE = {
            PANEL: @html.querySelector('.artist-info'),
            NAME: @html.querySelector('.artist-name'),
            AVATAR: @html.querySelector('.avatar'),
            BIO_TEXT: @html.querySelector('.bio-text'),
            CLOSE_BTN: @html.querySelector('.close-btn'),
            AVATAR_WRAPPER: @html.querySelector('.avatar-wrapper')
        }

        @bindEvents()

    initAttr: () ->
        @API = {
            ARTIST: "#{config.host}:#{config.port}/api/music/artist"
        }

        @TIPS = {
            EMPTY_INFO: '暂无此歌手相关信息。'
            NETWORK_ERROR: 'Oops！网络错误，请稍后重试...'
        }

        @IMG = {
            SIZE: '500x500',
            DEFAULT_AVATAR: 'assets/avatar.png'
        }

    render: () ->
        htmls = """
            <div class="artist-info">
                <div class="close-btn" title="关闭"></div>
                <div class="artist-avatar">
                    <div class="avatar-wrapper">
                        <img alt="AVATAR" class="avatar" src="#{@IMG.DEFAULT_AVATAR}" />
                    </div>
                    <p class="artist-name">歌手：歌手名</p>
                </div>
                <div class="artist-bio">
                    <div class="bio-text">歌手信息</div>
                </div>
            </div>
        """.replace /\n\s+/ig, ''

        @html.innerHTML = htmls
        @emit 'renderFinished'

    bindEvents: () ->
        $(@NODE.CLOSE_BTN).on 'click', (e) =>
            @close()

    # Render artist info
    # @param {object} info - info
    renderInfo: (info) ->
        name = info.name
        bio = info.bio or @TIPS.EMPTY_INFO
        avatar = @IMG.DEFAULT_AVATAR

        # Get avatar if exists
        len = info.images?.length
        if len > 0
            img = info.images[len - 1]['#text']
            img and avatar = img.replace(/arQ/g, @IMG.SIZE)
        # Ignore useless info
        bio = bio.replace(/<a href=.*/ig, '')

        # Load avatar
        @NODE.AVATAR_WRAPPER.classList.add 'loading'
        @NODE.AVATAR.onload = () =>
            @NODE.AVATAR_WRAPPER.classList.remove 'loading'
        @NODE.AVATAR.src = avatar

        @NODE.NAME.innerText = "歌手：#{name}"
        @NODE.BIO_TEXT.innerText = bio
        @NODE.BIO_TEXT.scrollTop = 0

    # Reset info panel
    reset: () ->
        @NODE.AVATAR.src = @IMG.DEFAULT_AVATAR
        @NODE.NAME.innerText = '歌手：歌手名'
        @NODE.BIO_TEXT.innerText = '歌手信息'

    # ---------------------------------------------------

    # Show the info of given artist
    # @param {string} artist - artist name
    show: (artist) ->
        $(@NODE.PANEL).parent().addClass 'expand'

        $.ajax {
            url: @API.ARTIST,
            type: 'GET',
            data: {
                artist: artist
            },
            beforeSend: () =>
                $(@NODE.PANEL).addClass 'loading'
            ,
            success: (data) =>
                if data?.status is 'success' and data?.artist
                    @renderInfo data.artist
                else
                    @NODE.BIO_TEXT.innerText = @TIPS.EMPTY_INFO
            ,
            error: () =>
                @NODE.BIO_TEXT.innerText = @TIPS.NETWORK_ERROR
            ,
            complete: () =>
                $(@NODE.PANEL).removeClass 'loading'
        }

    # Close the info panel
    close: () ->
        $(@NODE.PANEL).parent().removeClass 'expand'
        setTimeout () =>
            @reset()
        , 200

module.exports = ArtistInfo
