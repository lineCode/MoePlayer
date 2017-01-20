##
# MoePlayer Component
# @Author VenDream
# @Update 2017-1-20 17:34:59
##

BaseComp = require './BaseComp'
Util = require './Util'
Timer = require './Timer'
Dragger = require './Dragger'

class MoePlayer extends BaseComp
    constructor: (selector, eventBus) ->
        super selector, eventBus

        @initAttr()

    init: () ->
        @initNode()
        @bindEvents()

    # Init component attributes
    initAttr:() ->
        @LIST = []          # Song list
        @CUR_TIME = 0       # Current time
        @CUR_SONG = null    # Current song
        @CUR_INDEX = -1     # Current index
        @PLAY_MODE = 0      # Play mode

        # Create a HTML5 Audio object
        @PLAYER = new Audio()
        # Create a Timer object to detect audio buffering
        @BUFFER_TIMER = new Timer()
        # Create a Timer object to sync player progress
        @PROGRESS_TIMER = new Timer()
        # Create a Dragger object to enable dragging
        @DRAGGER = new Dragger()

        # Icons
        @ICONS = {
            COVER: 'assets/cover.png',
            PREV: 'assets/prev.png',
            NEXT: 'assets/next.png',
            PLAY: 'assets/play.png',
            PAUSE: 'assets/pause.png',
            VOLUME: 'assets/volume.png',
            MUTE: 'assets/mute.png',
            DEFAULT: 'assets/default_cover.jpg'
        }

        # Msg tips
        @TIPS = {
            ERROR: '歌曲URL无效QAQ',
            SWITCH: '歌曲URL无效，尝试切换音质...',
            STALLED: '音频数据不再可用，重新播放...'
        }

    # Init componet DOM nodes
    initNode: () ->
        @cover = @html.querySelector '.mp-cover'
        @control = @html.querySelector '.mp-control'
        @time = @html.querySelector '.mp-time'
        @volume = @html.querySelector '.mp-volume'
        @addons = @html.querySelector '.mp-addons'

        @prev = @control.querySelector '.prev-song'
        @status = @control.querySelector '.play-status'
        @next = @control.querySelector '.next-song'

        @playedTime = @time.querySelector '.played-time'
        @progressBar = @time.querySelector '.progress-bar'
        @bufferBar = @time.querySelector '.buffer-bar'
        @progressDragBar = @time.querySelector '.progress-drag-bar'
        @totalTime = @time.querySelector '.total-time'
        @quality = @time.querySelector '.song-quality'

        @volumeIcon = @volume.querySelector '.volume-icon'
        @volumeBar = @volume.querySelector '.volume-bar'
        @volumnColorBar = @volume.querySelector '.volume-color-bar'
        @volumeDragBar = @volume.querySelector '.volume-drag-bar'

        @playMode = @addons.querySelector '.play-mode'

    render: () ->
        htmls = 
            """
            <div class="moePlayer">
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
                            <div class="volume-color-bar"></div>
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
            """.replace /\n\s+/ig, ''

        @html.innerHTML = htmls
        @emit 'renderFinished'

    bindEvents: () ->
        @ctrlPlayer()
        @ctrlVolume()
        @ctrlProgress()
        @ctrlPlayMode()
        @ctrlUserAction()

    # Bind events for Audio player
    ctrlPlayer: () ->
        # Update currentTime
        @PLAYER.addEventListener 'timeupdate', () =>
            @eventBus.emit 'MoePlayer::UpdateTime', @PLAYER.currentTime

        # On progress
        @PLAYER.addEventListener 'progress', () =>
            @syncBuffer @PLAYER.buffered

        # On canplaythrough
        @PLAYER.addEventListener 'canplaythrough', () =>
            if not @CUR_SONG or @PROGRESS_TIMER.isSet()
                return false

            index = parseInt(@CUR_SONG?.song_info.idx) ? -1
            duration = @CUR_SONG?.song_info.song_duration

            # Trigger Audio.play()
            @PLAYER.play()

            # Update current index and duration
            @CUR_INDEX = index
            $(@totalTime).text Util.normalizeSeconds(duration)

            # Update play status icon
            $(@status)
                .removeClass 'small circle loading'
                .addClass('playing')
                .find('img').attr 'src', @ICONS.PAUSE

            # Sync progress
            @syncProgress duration
            @syncBuffer @PLAYER.buffered

            # Start buffering detector
            @detectBuffering()

        # On error
        @PLAYER.addEventListener 'error', (e) =>
            # Here error is a Media Error object
            errorType = [
                'MEDIA_ERR_ABORTED',
                'MEDIA_ERR_NETWORK',
                'MEDIA_ERR_DECODE',
                'MEDIA_ERR_SRC_NOT_SUPPORTED'
            ]
            error = e.currentTarget.error
            msg = errorType[error.code - 1]
            quality =  @CUR_SONG.song_info.song_quality

            # Try to fall back to poor quality
            if @CUR_SONG.source is 'QQ音乐' and quality >= 128
                if quality >= 320
                    higherRegex = /M800/ig
                    formatRegex = /\.mp3/ig
                    lowerKey = 'M500'
                    quality = 128
                    format = '.mp3'
                else
                    higherRegex = /M500/ig
                    formatRegex = /\.mp3/ig
                    lowerKey = 'C200'
                    quality = 48
                    format = '.m4a'

                poorUrl = @CUR_SONG.song_info.song_url
                    .replace(higherRegex, lowerKey)
                    .replace(formatRegex, format)

                @CUR_SONG.song_info.song_quality = quality
                @CUR_SONG.song_info.song_url = poorUrl

                Util.showMsg @TIPS.SWITCH, 3000
                @eventBus.emit 'MoePlayer::SwitchQuality', @CUR_SONG
            else
                @stop()
                # Util.showMsg @TIPS.ERROR, 3000, 3
                Util.showMsg "网络错误，错误原因: #{msg}", -1, 3
                $(@status).removeClass 'small circle loading'
                @eventBus.emit 'MoePlayer::UrlError'

    # Bind events for volume
    ctrlVolume: () ->
        name = 'Volume'
        vbw = $(@volumeBar).width()
        vdbw = $(@volumeDragBar).width()
        min = -vdbw / 2
        max = vbw - vdbw / 2
        total = vbw
        $vIcon = $(@volumeIcon).find('img')

        # Enable dragging volume-bar
        @DRAGGER.enableDragging @volumeDragBar, min, max, total, 0, @volume, name

        # Update volume
        @DRAGGER.on "Dragger::Dragging##{name}", (percent) =>
            @PLAYER.volume = percent

            $(@volumnColorBar).css {
                'width': "#{percent * 100}%"
            }

            if percent is 0
                $vIcon.attr 'src', @ICONS.MUTE
            else
                if $vIcon.attr('src') isnt @ICONS.VOLUME
                    $vIcon.attr 'src', @ICONS.VOLUME

    # Bind events for progress bar
    ctrlProgress: () ->
        name = 'Progress'

        enableDragging = () =>
            pbw = $(@progressBar).width()
            bbw = $(@bufferBar).width()
            pdbw = $(@progressDragBar).width()
            min = -pdbw / 2
            max = bbw - pdbw / 2
            total = pbw
            @DRAGGER.enableDragging @progressDragBar, min, max, total, 0, @time, name

        # Click progress-drag-bar to trigger dragging
        $(@progressDragBar).unbind().on 'mousedown', (e) =>
            if $(@status).hasClass('loading')
                return false
            @CUR_SONG and (
                @pause()
                enableDragging()
            )

        # On dragging
        @DRAGGER.on "Dragger::Dragging##{name}", (percent) =>
            @CUR_SONG and (
                totalTime = @CUR_SONG.song_info.song_duration / 1000
                curTime = totalTime * percent
                @CUR_TIME = Math.round curTime
                $(@playedTime).text Util.normalizeSeconds(@CUR_TIME, 1)
            )

        # On drag end
        @DRAGGER.on "Dragger::DragEnd##{name}", (percent) =>
            @CUR_SONG and (
                totalTime = @CUR_SONG.song_info.song_duration / 1000
                curTime = totalTime * percent
                @PLAYER.currentTime = curTime
                @detectBuffering curTime
                @DRAGGER.disableDragging @progressDragBar, @time
                @resume()
            )

        # On click buffer bar
        $(@bufferBar).unbind().on 'mousedown', (e) =>
            if $(@status).hasClass('loading')
                return false

            @CUR_SONG and (
                totalTime = @CUR_SONG.song_info.song_duration / 1000
                barLeft = @progressBar.getBoundingClientRect().left
                barWidth = $(@progressBar).width()
                dragBarWidth = $(@progressDragBar).width()
                offset =  Math.max(e.clientX - barLeft, 0)
                percent = offset / barWidth
                curTime = totalTime * percent

                @PLAYER.currentTime = curTime
                @CUR_TIME = Math.round curTime
                @detectBuffering curTime
                $(@playedTime).text Util.normalizeSeconds(@CUR_TIME, 1)
                $(@progressDragBar).css 'left', (offset - dragBarWidth / 2) + 'px'
                @eventBus.emit 'MoePlayer::Resume'
            )

    # Bind events for selecting play mode
    ctrlPlayMode: () ->
        $text = $(@playMode).find('.mode-text')

        $(@playMode).on 'click', (evt) =>
            switch @PLAY_MODE
                when 0
                    @PLAY_MODE = 1
                    $text.text '随机播放'
                    Util.toast '随机播放'
                    $(@playMode).attr 'class', 'play-mode random-mode'
                when 1
                    @PLAY_MODE = 2
                    $text.text '单曲循环'
                    Util.toast '单曲循环'
                    $(@playMode).attr 'class', 'play-mode loop-mode'
                when 2
                    @PLAY_MODE = 0
                    $text.text '顺序播放'
                    Util.toast '顺序播放'
                    $(@playMode).attr 'class', 'play-mode sequence-mode'

    # Bind events for user actions
    ctrlUserAction: () ->
        # Play | Pause
        $(@status).on 'click', (evt) =>
            evt.stopPropagation()
            $target = $(evt.currentTarget)

            if not @CUR_SONG or $(@status).hasClass('loading')
                return

            if $target.hasClass 'playing'
                @pause()
                Util.toast '暂停播放', {
                    color: '#ffffff',
                    duration: 1000
                }
            else
                @resume()
                Util.toast '恢复播放', {
                    color: '#ffffff',
                    duration: 1000
                }

        # Prev song
        $(@prev).on 'click', (evt) =>
            evt.stopPropagation()
            $target = $(evt.currentTarget)

            if @LIST.length is 0 or @CUR_INDEX is -1
                return false

            switch @PLAY_MODE
                when 0
                    prevIndex = Math.max(@CUR_INDEX - 1, 0)
                when 1
                    prevIndex = Util.random 0, @LIST.length - 1, @CUR_INDEX
                when 2
                    prevIndex = @CUR_INDEX

            prevSong = @LIST[prevIndex]
            @stop()
            @eventBus.emit 'MoePlayer::PlayPrevSong', {
                song_id: prevSong.song_id,
                idx: prevIndex
            }

        # Next song
        $(@next).on 'click', (evt) =>
            evt.stopPropagation()
            $target = $(evt.currentTarget)

            if @LIST.length is 0 or @CUR_INDEX is -1
                return false

            switch @PLAY_MODE
                when 0
                    nextIndex = Math.min(@CUR_INDEX + 1, @LIST.length - 1)
                when 1
                    nextIndex = Util.random 0, @LIST.length - 1, @CUR_INDEX
                when 2
                    nextIndex = @CUR_INDEX
            
            nextSong = @LIST[nextIndex]
            @stop()
            @eventBus.emit 'MoePlayer::PlayNextSong', {
                song_id: nextSong.song_id,
                idx: nextIndex
            }

        # Expend detail panel
        $(@cover).unbind().on 'click', () =>
            @CUR_SONG and @eventBus.emit 'MoePlayer::ExpandDetailPanel'

        # On cover loaded
        $(@cover).find('img').on 'load', () =>
            $(@cover).removeClass 'loading'

    # ---------------------------------------------------

    # Sync progress
    # @param {number} timeWidth - song duration
    syncProgress: (timeWidth) ->
        timeWidth = timeWidth / 1000

        # Decide stepWidth per second
        barWidth = parseFloat $(@progressBar).css('width')
        stepWidth = barWidth / timeWidth

        # Update position
        updatePos = () =>
            if @PLAYER.ended is true
                @stop()
                $(@next).trigger 'click'
                return

            curPos = parseFloat $(@progressDragBar).css('left')
            newPos = curPos + stepWidth
            @CUR_TIME += 1
            @CUR_TIME >= timeWidth and @CUR_TIME = Math.floor(timeWidth)

            $(@progressDragBar).css('left', newPos + 'px')
            $(@playedTime).text Util.normalizeSeconds(@CUR_TIME, 1)

        # Setup timer and start
        @PROGRESS_TIMER
            .set updatePos, 1000, true, 'PROGRESS_TIMER'
            .start()

    # Sync buffer
    # @param {TimeRange} buffered - buffered range
    syncBuffer: (buffered) ->
        @CUR_SONG and (
            total = @CUR_SONG.song_info.song_duration / 1000
            percent = buffered.length and buffered.end(buffered.length - 1) / total or 0.00
            percent < 0.0 and percent = 0.0
            percent > 1.0 and percent = 1.0
            $(@bufferBar).css 'width', (percent * 100) + '%'
        )

    # Detect if the player is buffering
    detectBuffering: (start = 0) ->
        checkInterval = 50
        lastPlayPos = start
        currPlayPos = start
        offset = 1 / checkInterval
        bufferingDetected = false

        doDetect = () =>
            currPlayPos = @PLAYER.currentTime

            if not @PLAYER.paused
                if not bufferingDetected and currPlayPos < (lastPlayPos + offset)
                    bufferingDetected = true
                    @PROGRESS_TIMER.pause()
                    $(@status).addClass 'small circle loading'
                    @eventBus.emit 'MoePlayer::Pause'
                if bufferingDetected and currPlayPos > (lastPlayPos + offset)
                    bufferingDetected = false
                    @PROGRESS_TIMER.resume()
                    $(@status).removeClass 'small circle loading'
                    @eventBus.emit 'MoePlayer::Resume'

            lastPlayPos = currPlayPos

        @BUFFER_TIMER
            .clear()
            .set doDetect, checkInterval, true, 'BUFFER_TIMER'
            .start()

    # Fix song url
    # @param {string} path - song url
    fixSongURL: (path) ->
        if @PLAYER.baseURI and @PLAYER.baseURI.indexOf('app.asar') >= 0 and \
        /^https?:\/\//g.test(path) is false
            path = "../../#{path}"

        return path

    # ---------------------------------------------------

    # Play
    # param {object} song - song object
    play: (song) ->
        @stop()

        # Load song
        @CUR_SONG = song
        @PLAYER.src = @fixSongURL(@CUR_SONG.song_info.song_url)
        @PLAYER.preload = 'auto'
        @PLAYER.load()

        # Set status icon
        $(@status).addClass 'small circle loading'

        # Set cover
        $(@cover).addClass 'loading'
            .find('img').attr 'src', @CUR_SONG.song_info.song_cover or @ICONS.DEFAULT

        # Set quality
        sq = parseInt(@CUR_SONG.song_info.song_quality)
        if sq >= 320
            $(@quality).text '高音质'
            @quality.className = 'song-quality high'
        else if 128 <= sq < 320
            $(@quality).text '中音质'
            @quality.className = 'song-quality medium'
        else
            $(@quality).text '低音质'
            @quality.className = 'song-quality low'

    # Resume
    resume: (isEmit = true) ->
        @PLAYER.play()
        $(@status).addClass 'playing'
        $(@status).find('img').attr 'src', @ICONS.PAUSE

        @PROGRESS_TIMER.resume()
        isEmit and @eventBus.emit 'MoePlayer::Resume'

    # Pause
    pause: (isEmit = true) ->
        @PLAYER.pause()
        $(@status).removeClass 'playing'
        $(@status).find('img').attr 'src', @ICONS.PLAY

        @PROGRESS_TIMER.pause()
        isEmit and @eventBus.emit 'MoePlayer::Pause'

    # Stop
    stop: () ->
        @PLAYER.pause()
        @CUR_TIME = 0
        @CUR_SONG = null
        @PLAYER.currentTime = 0
        @PROGRESS_TIMER.clear()
        @BUFFER_TIMER.clear()

        # Reset status icon and cover
        $(@status).removeClass 'playing'
            .find('img').attr 'src', @ICONS.PLAY
        $(@cover).find('img').attr 'src', @ICONS.COVER

        # Rest time
        $(@playedTime).text '00:00'
        $(@totalTime).text '00:00'

        # Reset quality
        $(@quality).text '默认'
        @quality.className = 'song-quality'

        # Reset progress bar and buffer bar
        oriPos = -$(@progressDragBar).width() / 2
        $(@progressDragBar).css('left', oriPos + 'px')
        $(@bufferBar).css 'width', 0

        # Stop timer
        @PROGRESS_TIMER.stop()
    
    # Update song list
    # @param {object} data - data
    updateList: (data) ->
        if data and data.songs
            @LIST = data.songs

    # Clear song list
    clearList: () ->
        @LIST = []

    # Map hotkeys
    # @param {number} kc - key code
    hotKeyResponse: (kc) ->
        switch kc
            # Type space to play or pause
            when 32
                $(@status).trigger 'click'

module.exports = MoePlayer
