##
# 播放器组件
# @Author VenDream
# @Update 2016-7-20 15:44:27
##

BaseComp = require './BaseComp'
Util = require './Util'

class MoePlayer extends BaseComp
	constructor: (selector, eventBus) ->
		super selector, eventBus

		@LIST = []
		@TIMER = 0
		@CUR_TIME = 0

		@ICONS = {
			COVER: 'assets/cover.png',
			PREV: 'assets/prev.png',
			NEXT: 'assets/next.png',
			PLAY: 'assets/play.png',
			PAUSE: 'assets/pause.png'
		}

	init: ->
		# common child
		@player = @html.querySelector '.mp-player'
		@cover = @html.querySelector '.mp-cover'
		@control = @html.querySelector '.mp-control'
		@time = @html.querySelector '.mp-time'
		@addons = @html.querySelector '.mp-addons'

		# detail child
		@prev = @control.querySelector '.prev-song'
		@status = @control.querySelector '.play-status'
		@next = @control.querySelector '.next-song'
		@playedTime = @time.querySelector '.played-time'
		@progressBar = @time.querySelector '.progress-bar'
		@dragBar = @time.querySelector '.drag-bar'
		@totalTime = @time.querySelector '.total-time'

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
							<div class="drag-bar"></div>
						</div>
						<div class="total-time">00:00</div>
					</div>
				</div>
				<div class="mp-part mp-addons"></div>
			</div>
			"""

		@html.innerHTML = htmls

		@emit 'renderFinished'

	eventBinding: ->
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
				@continue()

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

	# 把秒数格式化为 mm:ss 的格式
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
		# 记录正在播放的歌曲
		@curIndex = parseInt(song.idx)
		# 载入歌曲URL
		$(@player).attr 'src', song.url
		# 载入封面
		if song.cover
			$(@cover).find('img').attr 'src', song.cover
		# 切换图标状态
		$(@status).addClass 'playing'
			.find('img').attr 'src', @ICONS.PAUSE

		# 加载并播放歌曲
		$(@player).on 'loadeddata', =>
			@player.play()
			$(@totalTime).text @normalizeSeconds(@player.duration)
			@updateProgross @player.duration, true

	# 继续播放
	continue: ->
		@player.play()
		$(@status).addClass 'playing'
		$(@status).find('img').attr 'src', @ICONS.PAUSE

		@updateProgross()

	# 暂停播放
	pause: ->
		@player.pause()
		$(@status).removeClass 'playing'
		$(@status).find('img').attr 'src', @ICONS.PLAY

		clearTimeout @TIMER
	
	# 更新播放列表
	# @param {object} data 数据对象
	updateList: (data) ->
		if data and data.list
			@LIST = data.list

	# 更新播放进度
	# @param {number} timeWidth 总时间长度
	updateProgross: (timeWidth = @player.duration, isRestart = false) ->
		# 是否重新开始
		if isRestart is true
			@CUR_TIME = 0
			clearTimeout @TIMER
			oriPos = -parseFloat($(@dragBar).css('width')) / 2
			$(@dragBar).css('left', oriPos + 'px')

		# 计算每一秒进度指示器应该移动多少距离
		barWidth = parseFloat $(@progressBar).css('width')
		stepWidth = barWidth / timeWidth

		# 逐秒更新位置
		updatePos = =>
			curPos = parseFloat $(@dragBar).css('left')
			newPos = curPos + stepWidth
			$(@dragBar).css('left', newPos + 'px')
			@CUR_TIME += 1
			$(@playedTime).text @normalizeSeconds(@CUR_TIME)
			@TIMER = setTimeout updatePos, 1000

		updatePos()
			

module.exports = MoePlayer
