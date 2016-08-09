##
# 音乐列表组件
# @Author VenDream
# @Update 2016-8-9 14:04:21
##

BaseComp = require './BaseComp'
Util = require './Util'
Paginator = require './Paginator'
config = require '../../../config'
ipcRenderer = window.require('electron').ipcRenderer
fs = window.require 'fs'

class MusicList extends BaseComp
	constructor: (selector, eventBus) ->
		super selector, eventBus

		@TIPS = {
			SUGGEST: '搜索点什么听听吧ww',
			DOWNLOAD_START: '加入下载列表',
			DOWNLOAD_FAILED: '歌曲下载失败',
			DOWNLOAD_SUCCESS: '歌曲下载完成',
			NOT_FOUND_ERROR: '搜索不到相关的东西惹QAQ',
			NETWORK_ERROR: '服务器出小差啦，请重试QAQ',
			SONG_INFO_ERROR: '获取歌曲信息失败：歌曲已失效或需要付费'
		}

		@PAGINATOR = null
		@DLING_SONGS = []

	init: ->
		@api = "#{config.host}:#{config.port}/api/music/netease/song_info"
		@curSongId = ''

		@table = @html.querySelector 'table'
		@tipsRow = @html.querySelector '.tips-row'

		# 下载响应
		ipcRenderer.on 'ipcMain::DownloadSongSuccess', (event, s) =>
			@updateDLedSong s.song_id
			Util.showMsg "#{@TIPS.DOWNLOAD_SUCCESS}: 《#{s.song_name}》", null, 2
		ipcRenderer.on 'ipcMain::DownloadSongFailed', (event, err) =>
			Util.showMsg "#{@TIPS.DOWNLOAD_FAILED}: #{err}", null, 3

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
							<th class="list-duration">时长</th>
							<th class="list-operation">操作</th>
						</tr>
						<tr class="tips-row">
							<td colspan=6>#{@TIPS.SUGGEST}</td>
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
		# 双击播放
		$(@table).find('.song').unbind().on 'dblclick', (evt) =>
			evt.stopPropagation()
			$target = $(evt.currentTarget)
			idx = $target.attr 'data-idx'
			sid = $target.attr 'data-sid'

			sid && @getSongInfoAndPlay sid, idx

		# 下载歌曲
		$(@table).find('.dlBtn').unbind().on 'click', (evt) =>
			evt.stopPropagation()
			$song = $(evt.currentTarget).parents('.song')

			if $song.hasClass('hasDLed') is true or $song.hasClass('DLing') is true
				return false

			sn = $song.find('.title-col').text()
			sid = $song.attr 'data-sid'

			# Util.showMsg "#{@TIPS.DOWNLOAD_START}: 《#{sn}》"
			sid && @getSongInfoAndDownload sid

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
				@showTips @TIPS.NOT_FOUND_ERROR
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
			filepath = "#{config.save_path}/#{s.artist_name}/#{s.artist_name} - #{s.song_name}.mp3"
			isDLing = Util.checkInArr @DLING_SONGS, s.song_id
			hasDLed = Util.checkDLed filepath
			idx = Util.fixZero base + i + 1, @totalCount

			if isDLing is true
				c = 'DLing'
				t = '下载中'
			else
				if hasDLed is true
					c = 'hasDLed'
					t = '已下载'
				else
					t = '点击下载'

			trHtml = 
				"""
				<tr class="song not-select #{
					if String(s.song_id) is String(@curSongId) then 'playing' else ''
				} #{c}" data-sid="#{s.song_id}" data-idx="#{i}">
					<td class="index-col">#{idx}</td>
					<td class="title-col">#{s.song_name}</td>
					<td class="artist-col">#{s.artist_name}</td>
					<td class="album-col">#{s.album_name}</td>
					<td class="duration-col">#{Util.normalizeSeconds(s.duration)}</td>
					<td class="operation-col">
						<div class="btn dlBtn" title="#{t}"></div>
					</td>
				</tr>
				"""
			$tr = $(trHtml)

			# 设置title属性
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

	# 获取歌曲信息并播放
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
						Util.showMsg @TIPS.SONG_INFO_ERROR, 3000, 3
						return false
			, 
			error: (err) =>
				console.log err
		}

	# 获取歌曲信息并执行下载
	# @param {string} sid 歌曲ID
	getSongInfoAndDownload: (sid) ->
		$.ajax {
			type: 'POST',
			url: @api,
			data: {
				song_id: sid
			},
			success: (data) =>
				if data and data.status is 'success'
					if $.isEmptyObject(data.data.song_info) is false
						@updateDLingSong sid
						@eventBus.emit 'MusicList::DownloadSong', sid
						ipcRenderer.send 'ipcRenderer::DownloadSong', data.data.song_info
					else
						Util.showMsg @TIPS.SONG_INFO_ERROR, 3000, 3
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

	# 更新正在下载的歌曲
	# @param {string} sid 歌曲ID
	updateDLingSong: (sid) ->
		@DLING_SONGS.push sid

		$sr = $('.song[data-sid="' + sid + '"]')

		$sr.length > 0 && (
			$sr.addClass 'DLing'
			$sr.find('.dlBtn').attr 'title', '下载中'
		)

	# 更新已下载的歌曲
	# @param {string} sid 歌曲ID
	updateDLedSong: (sid) ->
		Util.removeFromArr @DLING_SONGS, sid

		$sr = $('.song[data-sid="' + sid + '"]')

		$sr.length > 0 && (
			$sr.removeClass 'DLing'
				.addClass 'hasDLed'
			$sr.find('.dlBtn').attr 'title', '已下载'
		)

module.exports = MusicList
