##
# 分页组件(封装Jquery的Pagination组件)
# @Author VenDream
# @Update 2016-7-29 18:12:02
##

BaseComp = require './BaseComp'
config = require '../../../config'

class Paginator extends BaseComp
	constructor: (selector, eventBus, maxEntries, opts) ->
		super selector, eventBus
		# 配置参数说明
		# items_per_page      {number}   每页显示的条目数
		# num_display_entries {number}   连续分页主体部分显示的分页条目数
		# current_page        {number}   当前选中的页面
		# num_edge_entries    {number}   两侧显示的首尾分页的条目数
		# link_to             {string}   分页的链接
		# prev_text           {string}   '上一页'按钮显示的文字
		# next_text           {string}   '下一页'按钮显示的文字
		# ellipse_text        {string}   省略的页数显示的字样
		# prev_show_always    {boolean}  是否显示'上一页'按钮
		# next_show_always    {boolean}  是否显示'下一页'按钮
		# show_if_single_pag  {boolean}  只有一页时是否显示
		# load_first_page     {boolean}  是否预加载第一页
		# callback            {function} 分页被点击后的回调
		@oriConfig =
			items_per_page: config.num_per_page
			num_display_entries: 7
			current_page: 0
			num_edge_entries: 1
			link_to: '#'
			prev_text: '上一页'
			next_text: '下一页'
			ellipse_text: '...'
			prev_show_always: true
			next_show_always: true
			show_if_single_page: true,
			load_first_page: false,
			callback: ->
				return false

		@userConfig = jQuery.extend @oriConfig, opts or {}
		@curPage = 0
		@maxEntries = maxEntries

		@calMaxPage()
		@render()

	init: ->
		@total = @html.querySelector '.total-num'
		@paginator = @html.querySelector '.paginator'
		@targetPageInput = @html.querySelector '.target-page-input'
		@jumpBtn = @html.querySelector '.jump-btn'

		@doPagination()
		@eventBinding()

	render: ->
		htmls = 
			"""
			<div class='p-container'>
				<div class='p-total'>
					共<span class="total-num">0</span>条记录
				</div>
				<div class='p-list'>
					<ul class='paginator pagination pagination-sm'></ul>
				</div>
				<div class='p-jump'>
					<div class="go-to">
						跳转到第
						<input type="number" min=1 max=#{@maxPages} value="1" class="target-page-input"></input>
						页
						<span class="jump-btn">
							GO
						</span>
					</div>
				</div>
			</div>
			"""

		@html.innerHTML = htmls
		@emit 'renderFinished'

	# 计算总页数
	# @param {number} maxEntries 数据项总数
	calMaxPage: (maxEntries = @maxEntries) ->
		tmpMaxPages = Math.ceil(maxEntries / @userConfig.items_per_page)
		if tmpMaxPages is 0
			@maxPages = 1
		else
			@maxPages = tmpMaxPages

	# 调用Jquery的分页操作
	# @param {number} maxEntries 数据项总数
	# @param {object} config     用户配置
	doPagination: (maxEntries = @maxEntries, config = @userConfig) ->
		@curPage = 0
		@calMaxPage maxEntries

		$(@targetPageInput).attr 'max', @maxPages
			.val @curPage + 1
		$(@total).text maxEntries

		$(@paginator).pagination maxEntries, config

	# 事件绑定
	eventBinding: ->
		# input的值改变时进行简单的表单验证
		$(@targetPageInput).on 'change', (evt) =>
			$target = $(evt.target)
			value = Math.round parseInt($target.val())
			if 1 <= value <= @maxPages
				@curPage = value - 1
			else if value < 1
				@curPage = 0
			else if value > @maxPages
				@curPage = @maxPages - 1

		# 按下Enter键
		.on 'keydown', (evt) =>
			if evt.keyCode is 13
				$(evt.target).trigger 'change'
				$(@jumpBtn).trigger 'click'

		# 点击跳转按钮
		$(@jumpBtn).on 'click', (evt) =>
			$(@targetPageInput).val @curPage + 1
			@jumpToPage @curPage

	# 跳转到某一页
	# @param {number} targetPage 目标页数
	jumpToPage: (targetPage) ->
		$(@paginator).trigger 'setPage', [targetPage]

module.exports = Paginator
