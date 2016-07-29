##
# 音乐列表组件
# @Author VenDream
# @Update 2016-7-29 18:12:14
##

BaseComp = require './BaseComp'
Util = require './Util'
Paginator = require './Paginator'
config = require '../../../config'

class MusicList extends BaseComp
	constructor: (selector, eventBus) ->
		super selector, eventBus

		@TIPS = {
			SUGGEST: '搜索点什么听听吧ww',
			NOT_FOUND: '搜索不到相关的东西惹QAQ',
			NETWORK_ERROR: '服务器出小差啦，请重试QAQ',
			SONG_INFO_ERROR: '获取歌曲播放地址失败鸟（┬＿┬）\n\n原因：1.歌曲失效 2.收费歌曲'
		}

		@PAGINATOR = null

	init: ->
		@api = "#{config.host}:#{config.port}/api/music/netease/song_info"
		@curSongId = ''

		@table = @html.querySelector 'table'
		@tipsRow = @html.querySelector '.tips-row'

		@updatePagination 0

	render: ->
		htmls =
			"""
			<div class="musicList">
				<div class="table-c">
					<table>
						<tr>
							<th class="list-index"></th>
							<th class="list-title">标题</th>
							<th class="list-artist">歌手</th>
							<th class="list-album">专辑</th>
							<th class="list-operation">操作</th>
						</tr>
						<tr class="tips-row">
							<td colspan=5>#{@TIPS.SUGGEST}</td>
						</tr>
					</table>
				</div>
				<div class="mpc"></div>
			</div>
			"""

		@html.innerHTML = htmls

		@emit 'renderFinished'

	# 事件绑定
	eventBinding: ->
		$(@table).find('.song .operation-col').on 'click', (evt) =>
			$target = $(evt.target)
			idx = $target.attr 'data-idx'
			sid = $target.attr 'data-sid'

			sid && @getSongInfoAndPlay sid, idx

	# 渲染数据
	# @param {object}  data    数据
	# @param {boolean} refresh 是否为新的请求
	show: (data, refresh = true) ->
		$(@tipsRow).fadeOut 0

		if data and data.status is 'success'
			if data.data.songs
				base = (data.data.page - 1) * config.num_per_page
				@totalCount = data.data.count
				@showResult data.data.songs, base
				# 是否为新的搜索
				refresh && @updatePagination()

			if @totalCount is 0
				@showTips @TIPS.NOT_FOUND
		else
			@showTips @TIPS.NETWORK_ERROR

	# 显示错误提示信息
	# @param {string} msg 错误提示
	showTips: (msg = @TIPS.NETWORK_ERROR) ->
		# 清空原来的数据
		$(@table).find('.song').remove()

		# 显示错误信息
		$(@tipsRow).find('td').text msg
		$(@tipsRow).fadeIn 200

	# 显示搜索结果
	# @param {array}  songs 歌曲数组
	# @param {number} base  歌曲偏移基数
	showResult: (songs, base) ->
		# 清空原来的数据
		$(@table).find('.song').remove()

		# 渲染新的数据
		songs.map (s, i) =>
			idx = Util.fixZero base + i + 1, @totalCount
			trHtml = 
				"""
				<tr class="song #{
					if String(s.song_id) is String(@curSongId) then 'playing' else ''
				}" data-sid="#{s.song_id}">
					<td class="index-col">#{idx}</td>
					<td class="title-col">#{s.song_name}</td>
					<td class="artist-col">#{s.artist_name}</td>
					<td class="album-col">#{s.album_name}</td>
					<td class="operation-col" 
						data-aid="#{s.album_id}" 
						data-sid="#{s.song_id}"
						data-idx="#{i}">播放</td>
				</tr>
				"""
			$tr = $(trHtml)

			$tr.find('.album-col').map (i, t) ->
				$(t).attr 'title', $(@).text()

			$(@table).append $tr

		@eventBinding()

	# 更新分页
	# @param {number} maxEntries 数据项总数
	updatePagination: (maxEntries = @totalCount) ->
		if not @PAGINATOR?
			@PAGINATOR = new Paginator '.mpc', @eventBus, maxEntries, {
				callback: (pageIndex, container) =>
					@eventBus.emit 'MusicList::SelectPage', pageIndex + 1
			}
		else
			@PAGINATOR.doPagination maxEntries

	# 清空搜索结果
	clear: ->
		$(@table).find('.song').remove()

		@updatePagination 0
		@showTips @TIPS.SUGGEST

	# 根据歌曲ID获取歌曲信息
	# @param {string} sid 歌曲ID
	# @param {number} idx 歌曲索引
	getSongInfoAndPlay: (sid, idx) ->
		$.ajax {
			type: 'POST',
			url: @api,
			data: {
				song_id: sid
			},
			success: (data) =>
				if data and data.status is 'success'
					if $.isEmptyObject(data.data.song_info) is false
						data.data.song_info.idx = idx
						@updatePlayingSong sid
						@eventBus.emit 'MusicList::PlaySong', data.data
					else
						alert @TIPS.SONG_INFO_ERROR
						return false
			, 
			error: (err) =>
				console.log err
		}

	# 更新显示正在播放的歌曲
	# @param {string} sid 歌曲ID
	updatePlayingSong: (sid) ->
		@curSongId = sid
		$sr = $('.song[data-sid="' + sid + '"]')
		$sr.length > 0 && (
			$('.song').removeClass 'playing'
			$sr.addClass 'playing'
		)

module.exports = MusicList
