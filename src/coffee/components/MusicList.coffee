##
# 音乐列表组件
# @Author VenDream
# @Update 2016-7-20 09:15:58
##

BaseComp = require './BaseComp'

class MusicList extends BaseComp
	constructor: (selector, eventBus) ->
		super selector, eventBus

		@TIPS = {
			SUGGEST: '搜索点什么听听吧ww',
			NOT_FOUND: '搜索不到相关的东西惹QAQ',
			NETWORK_ERROR: '服务器错误，请重试QAQ'
		}

	init: ->
		@table = @html.querySelector 'table'
		@tipsRow = @html.querySelector '.tips-row'

	render: ->
		htmls =
			"""
			<div class="musicList">
				<table>
					<tr>
						<th class="list-index"></th>
						<th class="list-title">标题</th>
						<th class="list-artist">歌手</th>
						<th class="list-operation">操作</th>
					</tr>
					<tr class="tips-row">
						<td colspan=4>#{@TIPS.SUGGEST}</td>
					</tr>
				</table>
			</div>
			"""

		@html.innerHTML = htmls

		@emit 'renderFinished'

	show: (data) ->
		$(@tipsRow).fadeOut 0

		if data and data.count
			@totalCount = data.count

		if data.list and data.list.length > 0
			@showResult data.list
		else
			@showError @TIPS.NOT_FOUND

	# 显示错误提示信息
	# @param {string} msg 错误提示
	showError: (msg = @TIPS.NETWORK_ERROR) ->
		# 清空原来的数据
		$(@table).find('.song').remove()

		# 显示错误信息
		$(@tipsRow).find('td').text msg
		$(@tipsRow).fadeIn 200

	# 显示搜索结果
	# @param {array} list 歌曲数组
	showResult: (list) ->
		# 清空原来的数据
		$(@table).find('.song').remove()

		# 渲染新的数据
		list.map (s, i) =>
			idx = @fixZero i + 1, @totalCount
			trHtml = 
				"""
				<tr class="song">
					<td>#{idx}</td>
					<td class="title-col">#{s.title}</td>
					<td>#{s.artist}</td>
					<td class="operation-col" 
						data-cover="#{s.cover}" 
						data-url="#{s.url}">播放</td>
				</tr>
				"""
			$tr = $(trHtml)

			$(@table).append $tr

		@eventBinding()

	# 事件绑定
	eventBinding: ->
		$(@table).find('.song .operation-col').on 'click', (evt) =>
			$target = $(evt.target)

			song = {
				url: $target.attr('data-url'),
				cover: $target.attr('data-cover')
			}

			@eventBus.emit 'MusicList::PlaySong', song

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

module.exports = MusicList
