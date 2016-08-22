##
# 拖拽组件
# @Author VenDream
# @Update 2016-7-27 14:16:43
##

EventEmitter = require 'eventemitter3'

class Dragger extends EventEmitter
    constructor: ->
        @init()

    init: ->
        @isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry/i.test(navigator.userAgent)
        
        if @isMobile is true
            @dragStart = 'touchstart'
            @dragMove = 'touchmove'
            @dragEnd = 'touchend'
        else
            @dragStart = 'mousedown'
            @dragMove = 'mousemove'
            @dragEnd = 'mouseup'

    # 为元素绑定拖拽事件
    # @param {element} ele       绑定对象
    # @param {number}  min       拖拽范围下界
    # @param {number}  max       拖拽范围上界
    # @param {number}  direction 拖拽方向(0 = 水平，1 = 竖直)
    # @param {element} zone      拖拽生效的区域
    enableDragging: (ele, min = 0, max = 100, direction = 0, zone = ele) ->
        $ele = $(ele)
        $zone = $(zone)
        start = 0
        end = 0
        delta = 0
        style = if direction is 0 then 'left' else 'top'
        origin = parseFloat($ele.css style)
        newPos = 0

        $ele.addClass 'draggable'

        # 拖拽开始，记录起始位置
        $zone.unbind().on @dragStart, (evt) =>
            $target = $(evt.target)
            if $target.hasClass('draggable') is true
                $target.addClass 'dragging'
            if @isMobile is true
                start = if direction is 0 \
                        then evt.touches[0].pageX \
                        else evt.touches[0].pageY
            else
                start = if direction is 0 \
                        then evt.pageX \
                        else evt.pageY

        # 拖拽进行，更新元素位置
        .on @dragMove, (evt) =>
            if $ele.hasClass('dragging') is false
                return false

            $zone.css 'cursor', 'pointer'

            if @isMobile is true
                move = if direction is 0 \
                       then evt.touches[0].pageX \
                       else evt.touches[0].pageY
            else
                move = if direction is 0 \
                       then evt.pageX \
                       else evt.pageY

            delta = move - start
            newPos = origin + delta
            newPos <= min && (
                newPos = min
            )
            newPos >= max && (
                newPos = max
            )

            $ele.css style, newPos + 'px'
            @emit 'Dragger::Dragging', Math.abs(newPos - min) / Math.abs(max - min)

        # 拖拽结束，更新起始位置
        .on @dragEnd, (evt) =>
            if $ele.hasClass('dragging') is false
                return false

            $zone.css 'cursor', 'default'

            if @isMobile is true
                end = if direction is 0 \
                      then evt.changedTouches[0].pageX \
                      else evt.changedTouches[0].pageY
            else
                end = if direction is 0 \
                      then evt.pageX \
                      else evt.pageY

            origin = newPos
            $ele.removeClass 'dragging'

    # 为元素取消拖拽绑定
    # @param {element} ele  取消对象
    # @param {element} zone 拖拽区域
    disableDragging: (ele, zone = ele) ->
        $(zone).unbind()

module.exports = Dragger
