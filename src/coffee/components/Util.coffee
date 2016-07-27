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
}
