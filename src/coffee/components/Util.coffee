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
}
