##
# 搜索框组件
# @Author VenDream
# @Update 2016-7-18 15:33:52
##

BaseComp = require './BaseComp'

class SearchBox extends BaseComp
	constructor: (selector, eventBus) ->
		super selector, eventBus

		@render()

	init: ->
		@api = ''

		@input = @html.querySelector '.searchInput'
		@btn = @html.querySelector '.goBtn'
		@loader = @html.querySelector '.loader'

		$(@loader).fadeOut 0
		@eventBinding()

	render: ->
		htmls = 
			"""
			<div class="searchBox">
				<input name="musicInfo" type="text" class="searchInput" 
					placeholder="输入歌曲信息（名称、歌手）" />
				<div class="goBtn">搜索</div>
				<div class="loader"></div>
			</div>
			"""

		@html.innerHTML = htmls
		@emit 'renderFinished'

	eventBinding: ->
		$(@btn).on 'click', =>
			sstr = $(@input).val()
			sstr && (
				@doSearch sstr
			)

	# 执行搜索
	# @param {string} sstr 关键词
	doSearch: (sstr) ->
		$.ajax {
			type: 'POST',
			url: @api,
			data: {
				sstr: sstr
			},
			beforeSend: =>
				$(@loader).fadeIn 200
			,
			complete: =>
				$(@loader).fadeOut 200	
			success: (data) =>
				console.log data
			,
			error: (err) =>
				console.log err
		}

module.exports = SearchBox
