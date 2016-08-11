##
# 歌词面板组件
# @Author VenDream
# @Update 2016-8-11 18:10:06
##

BaseComp = require './BaseComp'
Util = require './Util'

class LrcPanel extends BaseComp
	constructor: (selector, eventBus) ->
		super selector, eventBus

		@TAGS = {}
		@LRC_ARR = []

		# 预定义标签正则集合
		@TAG_REG_MAP = {
			# 艺术家
			AR: /\[ar:(.+)\]/
			# 曲名
			TI: /\[ti:(.+)\]/
			# 专辑名
			AL: /\[al:(.+)\]/
			# 歌词编辑者
			BY: /\[by:(.+)\]/
			# 时间补偿值
			OFFSET: /\[offset:(.+)\]/
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
		@lrcUL = @html.querySelector '.lrcUL'

	render: ->
		htmls = 
			"""
			<div class="lrcPanel">
				<div class="panel-c">
					<ul class="lrcUL">
					</ul>
				</div>
			</div>
			"""

		@html.innerHTML = htmls
		@emit 'renderFinished'

	eventBinding: ->

	renderLrc: (lrcArr = @LRC_ARR) ->
		$(@lrcPanel).removeClass 'empty'
		$(@lrcUL).empty()
		@LRC_ARR.map (lo, i) =>
			li = 
				"""
				<li data-line="#{lo.lineNo}" data-time="#{lo.time}">
					#{lo.text}
				</li>
				"""

			$(@lrcUL).append $(li)

	# 逐行解析LRC歌词数据
	# @param {string} lrc 歌词数据
	parseLrc: (lrc) ->
		@TAGS = {}
		@LRC_ARR = []

		# 获取Tag信息
		for tag, reg of @TAG_REG_MAP
			res = lrc.match reg
			@TAGS[tag] = res and res[1] or ''

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

					lineObj = {
						time: time and @getTime(time[1], time[2], time[3]) or ''
						text: text and text[1] or '\n'
						lineNo: i
					}

					@LRC_ARR.push lineObj
		)

	# 过滤歌词中的空格
	# # @param {string} lrc 歌词数据
	trim: (lrc) ->
		return lrc.replace /(^\s*|\s*$)/m, ''

	# 从[mm:ss.ff]中计算时间
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
	loadLrc: (lrc) ->
		if lrc
			@parseLrc @trim(lrc)
			@renderLrc @LRC_ARR
		else
			$(@lrcPanel).addClass 'empty'
			$(@lrcUL).empty()

	# 开始歌词滚动
	play: ->

	# 暂停歌词滚动
	pause: ->

	# 恢复歌词滚动
	resume: ->

	# 跳到指定时间点
	# @param {number} t 时间点
	seek: (t) ->

module.exports = LrcPanel
