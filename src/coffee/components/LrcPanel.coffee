##
# 歌词面板组件
# @Author VenDream
# @Update 2016-8-9 18:18:55
##

BaseComp = require './BaseComp'
Util = require './Util'

class LrcPanel extends BaseComp
	constructor: (selector, eventBus) ->
		super selector, eventBus

	init: ->

	render: ->
		htmls = 
			"""
			<div class="lrcPanel">
				<div class="panel-c">
				</div>
			</div>
			"""

		@html.innerHTML = htmls
		@emit 'renderFinished'

	eventBinding: ->

	#---------------------------------------------------
	#                     对外接口
	#---------------------------------------------------
	
	# 加载歌词数据
	# @param {string} lrc 歌词数据
	loadLrc: (lrc) ->

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
