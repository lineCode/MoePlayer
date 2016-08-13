##
# 歌词面板组件
# @Author VenDream
# @Update 2016-8-12 18:53:04
##

BaseComp = require './BaseComp'
Util = require './Util'

class LrcPanel extends BaseComp
	constructor: (selector, eventBus) ->
		super selector, eventBus

		@TAGS = {}
		@LRC_ARR = []
		@CUR_LINE = 0

		@CENTER_TOP = 0
		# 歌词行高(20px + 上下margin的6px，共32px)
		@LINE_HEIGHT = 32

		# 预定义标签正则集合
		@TAG_REG_MAP = {
			# 艺术家
			AR: /\[ar:([^\[\]:]+)\]\\n/
			# 曲名
			TI: /\[ti:([^\[\]:]+)\]\\n/
			# 专辑名
			AL: /\[al:([^\[\]:]+)\]\\n/
			# 歌词编辑者
			BY: /\[by:([^\[\]:]+)\]\\n/
			# 时间补偿值
			OFFSET: /\[offset:([^\[\]:]+)\]\\n/
		}

		# 时间标签正则集合
		@CONTENT_REG_MAP = {
			# 时间
			TIME: /\[(\d{2,}):(\d{2})\.(\d{2,3})\]/g
			# 歌词内容
			TEXT: /\[\d{2,}:\d{2}\.\d{2,3}\](.+)/g
		}

	init: ->
		@lrcPanel = @html.querySelector '.lrcPanel'
		@panel = @html.querySelector '.panel-c'
		@lrcUL = @html.querySelector '.lrc-ul'

	render: ->
		htmls = 
			"""
			<div class="lrcPanel">
				<div class="panel-c">
					<ul class="lrc-ul">
					</ul>
				</div>
			</div>
			"""

		@html.innerHTML = htmls
		@emit 'renderFinished'

	eventBinding: ->

	# 渲染歌词数据
	# @param {array} lrcArr 歌词数据
	renderLrc: (lrcArr = @LRC_ARR) ->
		$(@lrcPanel).removeClass 'empty'
		$(@lrcUL).empty()
		$(@lrcUL).css 'margin-top', 0

		@LRC_ARR.map (lo, i) =>
			li = 
				"""
				<li data-line="#{lo.lineNo}"
					data-offset="#{lo.lineNo * @LINE_HEIGHT}">
					#{lo.text}
				</li>
				"""

			$(@lrcUL).append $(li)

		# 歌词数组逆序保存一次，方便后面的查找操作
		@LRC_ARR.reverse()

		# 获取高亮行应该处在的位置
		@CENTER_TOP = $(@panel).height() / 2 - @LINE_HEIGHT

	# 解析LRC歌词行文本
	# @param {string} line 歌词行文本
	parseLrcLine: (line) ->

	# 逐行解析LRC歌词数据
	# @param {string} lrc 歌词数据
	# 
	# LRC歌词标准格式：
	# 
	# --------------------(预定义标签)
	# [ar:艺人名]
	# [ti:曲名]
	# [al:专辑名]
	# [by:歌词编辑者]
	# [offset:时间补偿值]
	# 
	# --------------------(时间标签)
	# [mm:ss.ff] 歌词文本 (分钟:秒数.毫秒数)
	# 如：[00:32.390]月明かり昇る刻
	# 
	parseLrc: (lrc) ->
		@TAGS = {}
		@LRC_ARR = []
		@CUR_LINE = 0

		# 获取Tag信息
		for tag, reg of @TAG_REG_MAP
			res = lrc.match reg
			@TAGS[tag] = res and res[1] or ''

			lrc = lrc.replace reg, ''

		# 获取内容信息
		lineArr = lrc.split '\\n'
		lineArr.length > 0 && (
			lineArr.map (line, i) =>
				line = @trim line

				if line isnt ''
					time = @CONTENT_REG_MAP.TIME.exec line
					text = @CONTENT_REG_MAP.TEXT.exec line

					# exec匹配完之后，如果要检索新的字符串，必须手动把lastIndex重置为0
					@CONTENT_REG_MAP.TIME.lastIndex = 0
					@CONTENT_REG_MAP.TEXT.lastIndex = 0

					# 无内容的歌词行不予显示
					if text?
						lineObj = {
							time: time and @getTime(time[1], time[2], time[3]) or 0
							text: text and text[1]
						}

						@LRC_ARR.push lineObj

			# 更新行数索引
			@LRC_ARR.map (lo, i) =>
				lo.lineNo = i

			# 更新排序
			@LRC_ARR.sort (a, b) ->
				return a.time - b.time			
		)

	# 根据时间点找到应该显示的行数
	# @param {number} t 时间点
	findLineByTime: (t) ->
		targetLine = 0

		for lo in @LRC_ARR
			if lo.time <= t
				targetLine = lo.lineNo
				break

		return targetLine

	# 更新目前应该显示的歌词行
	# @param {number} t 时间点
	updateShowingLine: (t) ->
		l = @findLineByTime t

		if @CUR_LINE isnt l or l is 0
			@CUR_LINE = l

			$line = $(@lrcUL).find("li[data-line=\"#{@CUR_LINE}\"]")

			# 高亮显示
			if l isnt 0
				$(@lrcUL).find('li').removeClass 'showing'
			if $line.hasClass('showing') is false
				$line.addClass 'showing'

			# 歌词滚动
			top = parseInt $line.attr('data-offset')
			if top > @CENTER_TOP # 歌词在中央部位以下，需要滚动
				offset = "#{-Math.abs(top - @CENTER_TOP)}px"
				$(@lrcUL).css 'margin-top', offset

		else
			return false

	# 过滤歌词中的空格
	# # @param {string} lrc 歌词数据
	trim: (lrc) ->
		return lrc.replace /(^\s*|\s*$)/m, ''

	# 从[mm:ss.ff]中计算时间，并转换为毫秒
	# @param {string} mm 分钟
	# @param {string} ss 秒数
	# @param {string} ff 毫秒数
	getTime: (mm, ss, ff) ->
		m = parseFloat mm
		s = parseFloat ss
		f = parseFloat(ff) or 0

		time = m * 60 * 1000 + s * 1000 + f

		return time

	#---------------------------------------------------
	#                     对外接口
	#---------------------------------------------------
	
	# 加载歌词数据
	# @param {string} lrc 歌词数据
	loadLrc: (lrc) ->
		if lrc
			@parseLrc @trim(lrc)
			@renderLrc @LRC_ARR
		else
			$(@lrcPanel).addClass 'empty'
			$(@lrcUL).empty()

	# 更新歌词滚动
	# @param {number} curTime 正在播放的时间点
	play: (curTime) ->
		# 转换为毫秒
		t = curTime * 1000

		@updateShowingLine t

	# 暂停歌词滚动
	pause: ->

	# 恢复歌词滚动
	resume: ->

	# 跳到指定时间点
	# @param {number} t 时间点
	seek: (t) ->
		@play t

module.exports = LrcPanel
