##
# 搜索框组件
# @Author VenDream
# @Update 2016-7-18 15:33:52
##

BaseComp = require './BaseComp'
config = require '../../../config.js'

class SearchBox extends BaseComp
	constructor: (selector, eventBus) ->
		super selector, eventBus

	init: ->
		@api = "#{config.host}:#{config.port}/API/music/NetEase/search"

		@input = @html.querySelector '.search-input'
		@btn = @html.querySelector '.go-btn'
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
				<div class="loader"></div>
			</div>
			"""

		@html.innerHTML = htmls
		@emit 'renderFinished'

	eventBinding: ->
		$(@btn).attr 'data-searching', '0'

		$(@btn).on 'click', =>
			sstr = $(@input).val()
			if sstr and $(@btn).attr('data-searching') is '0'
				@doSearch sstr

	# 执行搜索
	# @param {string} sstr 关键词
	doSearch: (sstr) ->
		$.ajax {
			type: 'POST',
			url: @api,
			data: {
				page: 1,
				sstr: sstr
			},
			beforeSend: =>
				$(@btn).attr 'data-searching', '1'
				$(@loader).fadeIn 200
			,
			complete: =>
				$(@btn).attr 'data-searching', '0'
				$(@loader).fadeOut 200	
			success: (data) =>
				if data and data.status is 'success'
					@eventBus.emit 'SearchBox::GetSearchResult', data.data
			,
			error: (err) =>
				console.log err
				@eventBus.emit 'SearchBox::NetworkError', err
		}

module.exports = SearchBox
