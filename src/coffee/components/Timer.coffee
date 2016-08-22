##
# 计时器组件
# @Author VenDream
# @Update 2016-7-29 18:13:23
##

class Timer
    constructor: ->

    # 设置计时器
    # @param {function} action 执行函数
    # @param {number}   delay  计时间隔
    # @param {boolean}  isLoop 是否循环计时
    set: (action, delay, isLoop = true) ->
        @stop()
        @clear()

        typeof action is 'function' && (
            @action = action
        )
        typeof delay is 'number' && (
            @remain = delay
            @delay = delay
        )
        typeof isLoop is 'boolean' && (
            @isLoop = isLoop
        )

        return @
        
    # 开始计时
    start: ->
        @resume()

        return @

    # 暂停计时
    pause: ->
        clearTimeout @timeId
        @endTL = new Date()
        @remain -= (@endTL - @startTL)
        # console.log '距离下一个循环开始还剩：%s s', @remain / 1000 

        return @

    # 恢复计时
    resume: ->
        @startTL = new Date()

        # console.time 'Action 实际执行间隔'
        @timeId = setTimeout =>
            # console.log 'Action 期望执行间隔: %sms', @delay.toFixed(3)
            # console.timeEnd 'Action 实际执行间隔'
            @excute()
        , @remain

        return @

    # 执行主体
    excute: ->
        @remain = @delay
        @action()

        if @isLoop is true and @isActive is true
            @resume()

        return @

    # 停止计时器
    stop: ->
        clearTimeout @timeId
        @isActive = false

        return @

    # 重置计时器
    clear: ->
        @timeId = 0
        @startTL = 0
        @endTL = 0
        @action = null
        @remain = 0
        @delay = 0
        @isLoop = true
        @isActive = true

        return @

module.exports = Timer
