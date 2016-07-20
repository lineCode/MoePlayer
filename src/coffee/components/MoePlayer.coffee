##
# 播放器组件
# @Author VenDream
# @Update 2016-7-20 15:44:27
##

BaseComp = require './BaseComp'

class MoePlayer extends BaseComp
	constructor: (selector, eventBus) ->
		super selector, eventBus

		@ICONS = {
			COVER: 'assets/cover.png',
			PREV: 'assets/prev.png',
			NEXT: 'assets/next.png',
			PLAY: 'assets/play.png',
			PAUSE: 'assets/pause.png'
		}

	init: ->
		@player = @html.querySelector '.mp-player'
		@cover = @html.querySelector '.mp-cover'
		@control = @html.querySelector '.mp-control'
		@addons = @html.querySelector '.mp-addons'

	render: ->
		htmls = 
			"""
			<div class="moePlayer">
				<audio class="mp-player hidden"></audio>
				<div class="mp-part mp-cover">
					<div class="cover-c">
						<img src="#{@ICONS.COVER}" alt="封面图片">
					</div>
				</div>
				<div class="mp-part mp-control">
					<div class="control-c">
						<div class="prev-song">
							<img src="#{@ICONS.PREV}" alt="上一首">
						</div>
						<div class="play-status">
							<img src="#{@ICONS.PLAY}" alt="播放">
						</div>
						<div class="next-song">
							<img src="#{@ICONS.NEXT}" alt="下一首">
						</div>
					</div>
				</div>
				<div class="mp-part mp-time"></div>
				<div class="mp-part mp-addons"></div>
			</div>
			"""

		@html.innerHTML = htmls

		@emit 'renderFinished'

	play: (song) ->
		$(@cover).find('img').attr 'src', song.cover

module.exports = MoePlayer
