##
# 工具函数
# @Author VenDream
# @Update 2016-8-3 18:06:57
##

module.exports = {
	# 根据总数进行补零操作
	# @param {number} n 待补零的数字
	# @param {number} t 总数
	fixZero: (n, t) ->
		totalLen = t.toString().length
		curLen = n.toString().length

		if totalLen is 1
			n = '0' + n
		else
			while curLen < totalLen
				n = '0' + n
				curLen += 1

		return n

	# 生成指定范围的随机正整数
	# @param {number} min 最小值
	# @param {number} max 最大值
	# @param {number} une 指定一个不希望随机到的值
	random: (min = 0, max = 1, une = null) ->
		if typeof min is 'number' and typeof max is 'number'
			result = Math.round(Math.random() * (min - max) + max)
			if result is une
				@random min, max, une
			else
				return result

	# 把秒数格式化为 mm:ss 的格式
	# @param {number} secs 秒数
	# @param {number} base 单位(默认为毫秒)
	normalizeSeconds: (secs, base = 1000) ->
		secs = Math.floor(secs / base)
		m = Math.floor secs / 60
		s = secs % 60

		return "#{@fixZero(m, 99)}:#{@fixZero(s, 99)}"

	# 移除页面选中效果
	clearSelection: ->
		document.selection && document.selection.empty && document.selection.empty()
		window.getSelection && window.getSelection().removeAllRanges()

	# 展示消息提示
	# @param {string} msg      提示文本（可含HTML标签）
	# @param {number} duration 消息持续时间(负数表示一直存在直到用户点击)
	# @param {number} level    级别（默认为正常）
	showMsg: (msg, duration = 2000, level = 0) ->
		if msg is ''
			return false

		$msgBox = $('.msgBox')
		if $msgBox.length <= 0
			$msgBox = $('<div class="msgBox"></div>')
			$('body').append $msgBox

		switch level
			when 0
				ln = 'normal'
			when 1
				ln = 'warning'
			when 2
				ln = 'success'
			when 3
				ln = 'error'
			else
				ln = 'normal'

		$msgLine = $("""<div class="msg-c slideIn #{ln}">#{msg}</div>""")
		$msgBox.append $msgLine

		if duration >= 0
			setTimeout ->
				te = 'webkitTramsitionEnd ' + 'mozTramsitionEnd ' + 
				     'MSTramsitionEnd ' + 'otransitionend ' + 'transitionend'
				ae = 'webkitAnimationEnd ' + 'mozAnimationEnd ' + 
				     'MSAnimationEnd ' + 'oanimationend ' + 'animationend'

				$msgLine.one ae, (evt) ->
					$(@).remove()
					if $msgBox.children().length is 0
						$msgBox.remove()

				$msgLine.removeClass 'slideIn'
					.addClass 'slideOut'
			, duration
}
