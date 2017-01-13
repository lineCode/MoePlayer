##
# 工具函数
# @Author VenDream
# @Update 2016-10-25 16:28:11
##

fs = window.require 'fs'
electron = window.require 'electron'
shell = electron.shell

module.exports = {
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

    # 生成指定范围的随机正整数
    # @param {number} min 最小值
    # @param {number} max 最大值
    # @param {number} une 指定一个不希望随机到的值
    random: (min = 0, max = 1, une = null) ->
        if typeof min is 'number' and typeof max is 'number'
            result = Math.round(Math.random() * (min - max) + max)
            if result is une
                @random min, max, une
            else
                return result

    # 把秒数格式化为 mm:ss 的格式
    # @param {number} secs 秒数
    # @param {number} base 单位(默认为毫秒)
    normalizeSeconds: (secs, base = 1000) ->
        secs = Math.floor(secs / base)
        m = Math.floor secs / 60
        s = secs % 60

        return "#{@fixZero(m, 99)}:#{@fixZero(s, 99)}"

    # 移除页面选中效果
    clearSelection: ->
        document.selection && document.selection.empty && document.selection.empty()
        window.getSelection && window.getSelection().removeAllRanges()

    # 检查本地磁盘中是否存在某文件
    # @param {string} filepath 文件路径 
    checkDLed: (filepath) ->
        try
            stat = fs.statSync filepath
            if stat
                rlt = true
        catch
            rlt = false

        return rlt

    # 过滤文件名的非法字符集
    # @param {string} filename 文件名
    filterFileName: (filename) ->
        r = filename.replace /[\/\\\:\?\*\<\>\|]/gi, '-'

        return r

    # 从数组中删除某元素
    # @param {array}         arr 数组
    # @param {string|number} ele 要删除的元素
    removeFromArr: (arr, ele) ->
        rlt = false
        if arr.length > 0
            arr.map (e, i) ->
                if e is ele
                    arr.splice i, 1
                    rlt = true

        return rlt

    # 检查元素是否在数组中
    # @param {array}         arr 数组
    # @param {string|number} ele 要检查的元素
    checkInArr: (arr, ele) ->
        rlt = false

        if arr.length > 0
            arr.map (e, i) ->
                if e is ele
                    rlt = true

        return rlt

    # 生产n位的唯一ID
    # @param {number} n ID长度
    uniqueId: (n) ->
        ID = ''
        while ID.length < n
            ID += Math.random().toString(36).substr(2)
        ID = ID.substr(0, n)

        return ID

    # 展示消息提示
    # @param {string} msg      提示文本（可含HTML标签）
    # @param {number} duration 消息持续时间(负数表示一直存在直到用户点击)
    # @param {number} level    级别（默认为正常）
    showMsg: (msg, duration = 3000, level = 0) ->
        if msg is ''
            return false

        $msgBox = $('.msgBox')
        if $msgBox.length <= 0
            $msgBox = $('<div class="msgBox"></div>')
            $('body').append $msgBox

        switch level
            when 0
                ln = 'normal'
            when 1
                ln = 'warning'
            when 2
                ln = 'success'
            when 3
                ln = 'error'
                # shell.beep()
            else
                ln = 'normal'

        $msgLine = $("""<div class="msg-c slideIn #{ln}">#{msg}</div>""")
        $msgBox.append $msgLine

        te = 'webkitTramsitionEnd ' + 'mozTramsitionEnd ' + 
             'MSTramsitionEnd ' + 'otransitionend ' + 'transitionend'
        ae = 'webkitAnimationEnd ' + 'mozAnimationEnd ' + 
             'MSAnimationEnd ' + 'oanimationend ' + 'animationend'

        if duration >= 0
            setTimeout ->
                $msgLine.one ae, (evt) ->
                    $(@).remove()
                    if $msgBox.children().length is 0
                        $msgBox.remove()

                $msgLine.removeClass 'slideIn'
                    .addClass 'slideOut'
            , duration
        else
            $msgLine.on 'click', ->
                $msgLine.one ae, (evt) ->
                    $(@).remove()
                    if $msgBox.children().length is 0
                        $msgBox.remove()
                $(@).removeClass 'slideIn'
                    .addClass 'slideOut'

    # 显示toast通知
    # @param {string} msg    toast消息文本
    # @param {object} option toast选项
    # 
    # option可选配置：
    # duration toast持续时间，负数则表示一直显示直到用户点击(可选)
    # height   toast窗体高度(可选)
    # width    toast窗体宽度(可选)
    # color    toast消息文本前景色(可选)
    toast: (msg, option) ->
        if msg is ''
            return false

        color = option and option.color or '#4caf50'
        duration = option and option.duration or 2000
        height = option and parseInt(option.height) or 5
        width = option and parseInt(option.width) or 20

        uniqueId = @uniqueId 8
        $tw = $("<div class=\"toastWrapper #{uniqueId}\"></div>")
        ae = 'webkitAnimationEnd ' + 'mozAnimationEnd ' + 
             'MSAnimationEnd ' + 'oanimationend ' + 'animationend'

        $('.toastWrapper').one ae, (evt) ->
            $(@).remove()
        .addClass 'zoomOut'

        $('body').append $tw

        $tw.text msg
            .addClass 'zoomIn'
            .css {
                'color': color,
                'height': height + 'rem',
                'width': width + 'rem',
                'marginLeft': (- width / 2) + 'rem',
                'marginTop': (- height / 2) + 'rem'
            }

        if duration >= 0
            setTimeout ->
                $tw.one ae, (evt) ->
                    $(@).remove()
                .removeClass 'zoomIn'
                .addClass 'zoomOut'
            , duration
        else
            $tw.on 'click', (evt) ->
                $(@).removeClass 'zoomIn'
                    .addClass 'zoomOut'
}
