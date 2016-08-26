##
# 播放器组件
# @Author VenDream
# @Update 2016-8-26 19:00:00
##

BaseComp = require './BaseComp'
Util = require './Util'
Timer = require './Timer'
Dragger = require './Dragger'

class MoePlayer extends BaseComp
    constructor: (selector, eventBus) ->
        super selector, eventBus

        @LIST = []
        @TIMER = null
        @DRAGGER = null
        @CUR_TIME = 0
        @CUR_SONG = null
        @PLAY_MODE = 0
        @STALLED_TIME = null

        @ICONS = {
            COVER: 'assets/cover.png',
            PREV: 'assets/prev.png',
            NEXT: 'assets/next.png',
            PLAY: 'assets/play.png',
            PAUSE: 'assets/pause.png',
            VOLUME: 'assets/volume.png',
            MUTE: 'assets/mute.png'
        }

        @TIPS = {
            URL_ERROR: '播放地址无效QAQ',
            STALLED: '网络不太给力啊QAQ'
        }

    init: ->
        # common child
        @player = @html.querySelector '.mp-player'
        @cover = @html.querySelector '.mp-cover'
        #-------------
        @control = @html.querySelector '.mp-control'
        @time = @html.querySelector '.mp-time'
        @volume = @html.querySelector '.mp-volume'
        @addons = @html.querySelector '.mp-addons'

        # detail child
        @prev = @control.querySelector '.prev-song'
        @status = @control.querySelector '.play-status'
        @next = @control.querySelector '.next-song'
        #-------------
        @playedTime = @time.querySelector '.played-time'
        @progressBar = @time.querySelector '.progress-bar'
        @bufferBar = @time.querySelector '.buffer-bar'
        @progressDragBar = @time.querySelector '.progress-drag-bar'
        @totalTime = @time.querySelector '.total-time'
        @quality = @time.querySelector '.song-quality'
        #-------------
        @volumeIcon = @volume.querySelector '.volume-icon'
        @volumeBar = @volume.querySelector '.volume-bar'
        @volumeDragBar = @volume.querySelector '.volume-drag-bar'
        #-------------
        @playMode = @addons.querySelector '.play-mode'

        @defaultCover = 'assets/default_cover.jpg'
        @TIMER = new Timer()
        @DRAGGER = new Dragger()

        @eventBinding()

    render: ->
        htmls = 
            """
            <div class="moePlayer">
                <audio preload="auto" class="mp-player hidden"></audio>
                <div class="mp-part mp-cover not-select">
                    <div class="cover-c">
                        <img src="#{@ICONS.COVER}" alt="封面图片">
                    </div>
                </div>
                <div class="mp-part mp-control not-select">
                    <div class="control-c">
                        <div class="prev-song">
                            <img src="#{@ICONS.PREV}" alt="上一首">
                        </div>
                        <div class="play-status">
                            <img src="#{@ICONS.PLAY}" alt="播放">
                        </div>
                        <div class="next-song">
                            <img src="#{@ICONS.NEXT}" alt="下一首">
                        </div>
                    </div>
                </div>
                <div class="mp-part mp-time not-select">
                    <div class="time-c">
                        <div class="played-time">00:00</div>
                        <div class="progress-bar">
                            <div class="buffer-bar"></div>
                            <div class="progress-drag-bar"></div>
                        </div>
                        <div class="total-time">00:00</div>
                        <div class="song-quality">默认</div>
                    </div>
                </div>
                <div class="mp-part mp-volume not-select">
                    <div class="volume-c">
                        <div class="volume-icon">
                                <img src="#{@ICONS.VOLUME}" alt="音量">
                            </div>
                        <div class="volume-bar">
                            <div class="volume-drag-bar"></div>
                        </div>
                    </div>
                </div>
                <div class="mp-part mp-addons not-select">
                    <div class="addons-c">
                        <div class="play-mode sequence-mode" title="模式切换">
                            <div class="mode-icon"></div>
                            <div class="mode-text">顺序播放</div>
                        </div>
                    </div>
                </div>
            </div>
            """

        @html.innerHTML = htmls

        @emit 'renderFinished'

    eventBinding: ->
        @playerBind()
        @progressBind()
        @volumeControl()
        @playModeControl()
        @playControl()

        $(@cover).unbind().on 'click', =>
            @CUR_SONG and @eventBus.emit 'MoePlayer::ExpandDetailPanel'

    # Audio事件绑定
    playerBind: ->
        $(@player).on 'timeupdate', =>
            @eventBus.emit 'MoePlayer::UpdateTime', @player.currentTime

    # 进度拖拽事件监听
    progressBind: ->
        name = 'Progress'

        @DRAGGER.on "Dragger::Dragging##{name}", (percent) =>
            @CUR_SONG && (
                totalTime = @CUR_SONG.song_info.song_duration / 1000
                curTime = totalTime * percent
                @CUR_TIME = Math.round curTime
                $(@playedTime).text Util.normalizeSeconds(@CUR_TIME, 1)
            )
        @DRAGGER.on "Dragger::DragEnd##{name}", (percent) =>
            @CUR_SONG && (
                totalTime = @CUR_SONG.song_info.song_duration / 1000
                curTime = totalTime * percent
                @player.currentTime = curTime
                @DRAGGER.disableDragging @progressDragBar, @time

                @resume()
            )

        $(@bufferBar).unbind().on 'mousedown', (e) =>
            @CUR_SONG && (
                totalTime = @CUR_SONG.song_info.song_duration / 1000
                barLeft = @progressBar.getBoundingClientRect().left
                barWidth = $(@progressBar).width()
                dragBarWidth = $(@progressDragBar).width()
                offset =  Math.max(e.clientX - barLeft, 0)
                percent = offset / barWidth
                curTime = totalTime * percent

                @player.currentTime = curTime

                @CUR_TIME = Math.round curTime
                $(@playedTime).text Util.normalizeSeconds(@CUR_TIME, 1)

                $(@progressDragBar).css 'left', (offset - dragBarWidth / 2) + 'px'
            )

        $(@progressDragBar).unbind().on 'mousedown', (e) =>
            @CUR_SONG && (
                @pause()
                @regProgressDragging()
            )

    # 绑定进度条拖拽
    regProgressDragging: ->
        name = 'Progress'
        pbw = $(@progressBar).width()
        bbw = $(@bufferBar).width()
        pdbw = $(@progressDragBar).width()
        @DRAGGER.enableDragging @progressDragBar, -pdbw / 2, bbw - pdbw / 2, pbw, 0, @time, name

    # 音量控制
    volumeControl: ->
        # 拖拽绑定
        name = 'Volume'
        vbw = $(@volumeBar).width()
        vdbw = $(@volumeDragBar).width()
        $vIcon = $(@volumeIcon).find('img')
        @DRAGGER.enableDragging @volumeDragBar, -vdbw / 2, vbw - vdbw / 2, vbw, 0, @volume, name

        # 调节音量
        @DRAGGER.on "Dragger::Dragging##{name}", (percent) =>
            @player.volume = percent

            if percent is 0
                $vIcon.attr 'src', @ICONS.MUTE
            else
                if $vIcon.attr('src') isnt @ICONS.VOLUME
                    $vIcon.attr 'src', @ICONS.VOLUME

    # 播放模式控制
    playModeControl: ->
        $(@playMode).on 'click', (evt) =>
            switch @PLAY_MODE
                when 0
                    @PLAY_MODE = 1
                    $(@playMode).attr 'class', 'play-mode random-mode'
                    $(@playMode).find('.mode-text').text '随机播放'
                when 1
                    @PLAY_MODE = 2
                    $(@playMode).attr 'class', 'play-mode loop-mode'
                    $(@playMode).find('.mode-text').text '单曲循环'
                when 2
                    @PLAY_MODE = 0
                    $(@playMode).attr 'class', 'play-mode sequence-mode'
                    $(@playMode).find('.mode-text').text '顺序播放'

    # 播放控制
    playControl: ->
        # 播放暂停
        $(@status).on 'click', (evt) =>
            evt.stopPropagation()
            $target = $(evt.currentTarget)

            if not @CUR_SONG
                return

            # 播放状态
            if $target.hasClass 'playing'
                @pause()
            # 暂停状态
            else
                @resume()

        # 切换歌曲
        $(@prev).on 'click', (evt) =>
            evt.stopPropagation()
            $target = $(evt.currentTarget)

            if @LIST.length is 0 or @curIndex is undefined
                return false

            # 播放模式
            switch @PLAY_MODE
                when 0
                    prevIndex = Math.max(@curIndex - 1, 0)
                when 1
                    prevIndex = Util.random 0, @LIST.length - 1, @curIndex
                when 2
                    prevIndex = @curIndex

            prevSong = @LIST[prevIndex]

            @eventBus.emit 'MoePlayer::PlayPrevSong', {
                song_id: prevSong.song_id,
                idx: prevIndex
            }

            @stop()

        $(@next).on 'click', (evt) =>
            evt.stopPropagation()
            $target = $(evt.currentTarget)

            if @LIST.length is 0 or @curIndex is undefined
                return false

            # 播放模式
            switch @PLAY_MODE
                when 0
                    nextIndex = Math.min(@curIndex + 1, @LIST.length - 1)
                when 1
                    nextIndex = Util.random 0, @LIST.length - 1, @curIndex
                when 2
                    nextIndex = @curIndex
            
            nextSong = @LIST[nextIndex]
            @eventBus.emit 'MoePlayer::PlayNextSong', {
                song_id: nextSong.song_id,
                idx: nextIndex
            }

            @stop()


    # 同步播放进度
    # @param {number} timeWidth 总时间长度(毫秒)
    syncProgress: (timeWidth) ->
        timeWidth = timeWidth / 1000

        # 计数清零
        @CUR_TIME = 0

        # 计算每一秒进度指示器应该移动多少距离
        barWidth = parseFloat $(@progressBar).css('width')
        stepWidth = barWidth / timeWidth

        # 逐秒更新位置
        updatePos = =>
            if @player.ended is true
                @stop()
                $(@next).trigger 'click'
                return

            curPos = parseFloat $(@progressDragBar).css('left')
            newPos = curPos + stepWidth
            @CUR_TIME += 1
            @CUR_TIME >= timeWidth and @CUR_TIME = Math.floor(timeWidth)

            $(@progressDragBar).css('left', newPos + 'px')
            $(@playedTime).text Util.normalizeSeconds(@CUR_TIME, 1)

        @TIMER.set updatePos, 1000
            .start()

    # 同步缓冲进度
    # @param {TimeRange} buffered 已缓冲范围
    syncBuffer: (buffered) ->
        @CUR_SONG and (
            total = @CUR_SONG.song_info.song_duration / 1000
            percent = buffered.length and buffered.end(buffered.length - 1) / total or 0.00
            $(@bufferBar).css 'width', (percent * 100) + '%'
        )

    #---------------------------------------------------
    #                     对外接口
    #---------------------------------------------------

    # 播放
    # param {object} song 歌曲对象
    play: (song) ->
        @pause false

        # 加载歌曲数据
        $(@player).attr 'src', song.song_info.song_url
        @player.load()
        @player.play().then =>
            # 切换新歌曲
            @CUR_SONG = song
            @curIndex = parseInt(song.song_info.idx)
            # 切换图标状态
            $(@status).addClass 'playing'
                .find('img').attr 'src', @ICONS.PAUSE
            # 载入封面
            $(@cover).find('img').attr 'src', song.song_info.song_cover or @defaultCover
            # 载入总时长
            $(@totalTime).text Util.normalizeSeconds(song.song_info.song_duration)

            # 切换音质显示
            sq = parseInt(song.song_info.song_quality)
            if sq >= 320
                $(@quality).text '高音质'
                @quality.className = 'song-quality high'
            else if 128 <= sq < 320
                $(@quality).text '中音质'
                @quality.className = 'song-quality medium'
            else
                $(@quality).text '低音质'
                @quality.className = 'song-quality low'

            # 同步播放/缓冲进度
            @syncProgress song.song_info.song_duration
            @syncBuffer @player.buffered

            $(@player).unbind('progress').on 'progress', =>
                @syncBuffer @player.buffered

        .catch (e) =>
            @stop()
            @CUR_SONG = null
            @curIndex = undefined

            Util.showMsg @TIPS.URL_ERROR, 3000, 3
            @eventBus.emit 'MoePlayer::UrlError', song

    # 继续播放
    # @param {boolean} isEmit 是否发送事件
    resume: (isEmit = true) ->
        @player.play()
        $(@status).addClass 'playing'
        $(@status).find('img').attr 'src', @ICONS.PAUSE

        @TIMER.resume()

        isEmit and @eventBus.emit 'MoePlayer::Resume'

    # 暂停播放
    # @param {boolean} isEmit 是否发送事件
    pause: (isEmit = true) ->
        @player.pause()
        $(@status).removeClass 'playing'
        $(@status).find('img').attr 'src', @ICONS.PLAY

        @TIMER.pause()

        isEmit and @eventBus.emit 'MoePlayer::Pause'

    # 停止播放
    stop: ->
        @player.pause()
        $(@status).removeClass 'playing'
        $(@status).find('img').attr 'src', @ICONS.PLAY

        # 封面还原为默认
        $(@cover).find('img').attr 'src', @ICONS.COVER

        # 时间重置为 00:00
        $(@playedTime).text '00:00'
        $(@totalTime).text '00:00'

        # 音质还原
        $(@quality).text '默认'
        @quality.className = 'song-quality'

        # 进度指示器回到原位置
        oriPos = -$(@progressDragBar).width() / 2
        $(@progressDragBar).css('left', oriPos + 'px')
        $(@bufferBar).css 'width', 0

        # 解除缓冲进度同步
        $(@player).unbind('progress')

        @TIMER.stop()
    
    # 更新播放列表
    # @param {object} data 数据对象
    updateList: (data) ->
        if data and data.songs
            @LIST = data.songs

    # 清空播放列表
    clearList: ->
        @LIST = []

    # 快捷键响应
    # @param {number} kc 键码
    hotKeyResponse: (kc) ->
        switch kc
            # 空格键
            when 32
                $(@status).trigger 'click'

module.exports = MoePlayer
