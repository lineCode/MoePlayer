##
# 搜索框组件
# @Author VenDream
# @Update 2016-8-13 11:18:27
##

BaseComp = require './BaseComp'
config = require '../../../config.js'

class SearchBox extends BaseComp
	constructor: (selector, eventBus) ->
		super selector, eventBus

		@TIPS = {
			RETRY_TIPS: '请求失败了，尝试重新请求...0v0'
		}

	init: ->
		@sstr = ''
		@page = 1
		@api = "#{config.host}:#{config.port}/api/music/netease/search"

		@input = @html.querySelector '.search-input'
		@goBtn = @html.querySelector '.go-btn'
		@clearBtn = @html.querySelector '.clear-btn'
		@loader = @html.querySelector '.loader'

		$(@loader).fadeOut 0
		@eventBinding()

	render: ->
		htmls = 
			"""
			<div class="searchBox">
				<input name="music-info" type="text" class="search-input" 
					placeholder="输入歌曲信息（名称、歌手）" />
				<div class="go-btn not-select">搜索</div>
				<div class="clear-btn not-select">清空</div>
				<div class="loader"></div>
			</div>
			"""

		@html.innerHTML = htmls
		@emit 'renderFinished'

	eventBinding: ->
		$(@goBtn).attr 'data-searching', '0'

		# 搜索
		$(@goBtn).on 'click', (evt) =>
			val = $(@input).val()
			if val isnt '' and $(@goBtn).attr('data-searching') is '0'
				@doSearch val, 1

		# 清空
		$(@clearBtn).on 'click', (evt) =>
			@sstr = ''
			@page = 1
			$(@input).val ''
			@eventBus.emit 'SearchBox::ClearSearchResult'

		# Enter快捷键搜索
		$(@input).on 'keydown', (evt) =>
			evt.stopPropagation()
			kc = evt.keyCode
			if kc is 13
				$(@goBtn).trigger 'click'

	# 执行搜索
	# @param {string} sstr 关键词
	# @param {number} page 页码
	doSearch: (sstr = @sstr, page = @page) ->
		refresh = if sstr is @sstr then false else true
		if sstr is ''
			return false

		$.ajax {
			type: 'POST',
			url: @api,
			data: {
				page: page,
				sstr: sstr
			},
			beforeSend: =>
				$(@goBtn).attr 'data-searching', '1'
				$(@loader).fadeIn 200
			,
			complete: =>
				$(@goBtn).attr 'data-searching', '0'
				$(@loader).fadeOut 200	
			success: (data) =>
				@sstr = sstr
				@page = page
				data.data.page = @page
				@eventBus.emit 'SearchBox::GetSearchResult', {
					data: data
					refresh: refresh
				}
			,
			error: (err) =>
				# Util.showMsg @TIPS.RETRY_TIPS, 3000, 3
				# @eventBus.emit 'SearchBox::NetworkError', err
				@doSearch sstr, page
		}

module.exports = SearchBox
