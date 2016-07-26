##
# 播放器组件
# @Author VenDream
# @Update 2016-7-22 14:10:03
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

		@ICONS = {
			COVER: 'assets/cover.png',
			PREV: 'assets/prev.png',
			NEXT: 'assets/next.png',
			PLAY: 'assets/play.png',
			PAUSE: 'assets/pause.png',
			VOLUMN: 'assets/volumn.png',
			MUTE: 'assets/mute.png'
		}

	init: ->
		# common child
		@player = @html.querySelector '.mp-player'
		@cover = @html.querySelector '.mp-cover'
		@control = @html.querySelector '.mp-control'
		@time = @html.querySelector '.mp-time'
		@volumn = @html.querySelector '.mp-volumn'
		@addons = @html.querySelector '.mp-addons'

		# detail child
		@prev = @control.querySelector '.prev-song'
		@status = @control.querySelector '.play-status'
		@next = @control.querySelector '.next-song'

		@playedTime = @time.querySelector '.played-time'
		@progressBar = @time.querySelector '.progress-bar'
		@progressDragBar = @time.querySelector '.progress-drag-bar'
		@totalTime = @time.querySelector '.total-time'

		@volumnIcon = @volumn.querySelector '.volumn-icon'
		@volumnBar = @volumn.querySelector '.volumn-bar'
		@volumnDragBar = @volumn.querySelector '.volumn-drag-bar'


		@TIMER = new Timer()
		@DRAGGER = new Dragger()

		@eventBinding()

	render: ->
		htmls = 
			"""
			<div class="moePlayer">
				<audio class="mp-player hidden"></audio>
				<div class="mp-part mp-cover">
					<div class="cover-c">
						<img src="#{@ICONS.COVER}" alt="封面图片">
					</div>
				</div>
				<div class="mp-part mp-control">
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
				<div class="mp-part mp-time">
					<div class="time-c">
						<div class="played-time">00:00</div>
						<div class="progress-bar">
							<div class="progress-drag-bar"></div>
						</div>
						<div class="total-time">00:00</div>
					</div>
				</div>
				<div class="mp-part mp-volumn">
					<div class="volumn-c">
						<div class="volumn-icon">
								<img src="#{@ICONS.VOLUMN}" alt="音量">
							</div>
						<div class="volumn-bar">
							<div class="volumn-drag-bar"></div>
						</div>
					</div>
				</div>
				<div class="mp-part mp-addons not-select">
					<div class="addons-c">
						<div class="play-mode" data-mode=0>
							顺序
						</div>
					</div>
				</div>
			</div>
			"""

		@html.innerHTML = htmls

		@emit 'renderFinished'

	eventBinding: ->
		# 拖拽绑定
		vbw = $(@volumnBar).width()
		vdbw = $(@volumnDragBar).width()
		$icon = $(@volumnIcon).find('img')
		@DRAGGER.enableDragging @volumnDragBar, -vdbw / 2, vbw - vdbw / 2, 0
		# 调节音量
		@DRAGGER.on 'Dragger::Dragging', (percent) =>
			@player.volumn = percent

			if percent is 0
				$icon.attr 'src', @ICONS.MUTE
			else
				if $icon.attr('src') isnt @ICONS.VOLUMN
					$icon.attr 'src', @ICONS.VOLUMN
		
		# 播放暂停
		$(@status).on 'click', (evt) =>
			evt.stopPropagation()
			$target = $(evt.currentTarget)
			$icon = $target.find('img')

			if not $(@player).attr('src') or $(@player).attr('src') is ''
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

			if @LIST.length is 0 or @curIndex is undefined or @curIndex is 0
				return false
			prevIndex = Math.max(@curIndex - 1, 0)
			prevSong = @LIST[prevIndex]
			prevSong.idx = prevIndex
			@play prevSong

		$(@next).on 'click', (evt) =>
			evt.stopPropagation()
			$target = $(evt.currentTarget)

			if @LIST.length is 0 or @curIndex is undefined or @curIndex is @LIST.length - 1
				return false

			nextIndex = Math.min(@curIndex + 1, @LIST.length - 1)
			nextSong = @LIST[nextIndex]
			nextSong.idx = nextIndex
			@play nextSong

	# 开始同步播放进度
	# @param {number} timeWidth 总时间长度
	startProgress: (timeWidth = @player.duration) ->
		# 进度指示器回到最初的位置
		@CUR_TIME = 0
		$(@playedTime).text '00:00'
		oriPos = -$(@progressDragBar).width() / 2
		$(@progressDragBar).css('left', oriPos + 'px')

		# 计算每一秒进度指示器应该移动多少距离
		barWidth = parseFloat $(@progressBar).css('width')
		stepWidth = barWidth / timeWidth

		# 逐秒更新位置
		updatePos = =>
			if @player.ended is true
				@stop()
				return

			curPos = parseFloat $(@progressDragBar).css('left')
			newPos = curPos + stepWidth
			@CUR_TIME += 1

			$(@progressDragBar).css('left', newPos + 'px')
			$(@playedTime).text @normalizeSeconds(@CUR_TIME)

		@TIMER.set updatePos, 1000
			.start()

	# 把秒数格式化为 mm:ss 的格式
	# @param {number} secs 秒数
	normalizeSeconds: (secs) ->
		secs = Math.floor secs
		m = Math.floor secs / 60
		s = secs % 60

		return "#{Util.fixZero(m, 99)}:#{Util.fixZero(s, 99)}"

	#---------------------------------------------------
	#                     对外接口
	#---------------------------------------------------

	# 播放
	# param {object} song 歌曲对象
	play: (song) ->
		@pause()

		# 切换新歌曲
		@curIndex = parseInt(song.idx)

		# 切换图标状态
		$(@status).addClass 'playing'
			.find('img').attr 'src', @ICONS.PAUSE

		# 载入歌曲URL
		$(@player).attr 'src', song.url
		@player.load()

		# 加载数据并播放
		$(@player).unbind().on 'loadedmetadata', =>
			# 载入封面
			if song.cover
				$(@cover).find('img').attr 'src', song.cover
			else
				$(@cover).find('img').attr 'src', @ICONS.COVER
			# 载入总时长
			$(@totalTime).text @normalizeSeconds(@player.duration)
		.on 'canplay', =>
			@player.play()
			@startProgress @player.duration

	# 继续播放
	resume: ->
		@player.play()
		$(@status).addClass 'playing'
		$(@status).find('img').attr 'src', @ICONS.PAUSE

		@TIMER.resume()

	# 暂停播放
	pause: ->
		@player.pause()
		$(@status).removeClass 'playing'
		$(@status).find('img').attr 'src', @ICONS.PLAY

		@TIMER.pause()

	# 停止播放
	stop: ->
		$(@status).removeClass 'playing'
		$(@status).find('img').attr 'src', @ICONS.PLAY

		oriPos = -$(@progressDragBar)('width') / 2
		$(@progressDragBar).css('left', oriPos + 'px')

		@TIMER.stop()
	
	# 更新播放列表
	# @param {object} data 数据对象
	updateList: (data) ->
		if data and data.list
			@LIST = data.list

module.exports = MoePlayer
