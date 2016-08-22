##
# 组件基类，采用PubSub模式(引用第三方库-EventEmitter3)
# @Author VenDream
# @Update 2016-8-8 18:06:11
##

EventEmitter = require('eventemitter3')

class BaseComp extends EventEmitter
    # 组件构造函数
    # @param {string|object} selector 组件容器选择器/组件DOM节点
    # @param {object}        eventBus 事件代理总线(可选)
    constructor: (selector, eventBus = null) ->
        @html = null
        @eventBus = eventBus

        # 如果是选择器，查找对应的元素节点
        if typeof selector is 'string'
            node = document.querySelector selector
        # 如果是元素节点，则直接用来初始化
        else if typeof selector is 'object' and selector.nodeType and selector.nodeType is 1
            node = selector

        # 保证DOM上存在这个元素节点后，初始化组件的HTML
        if node and node.getAttribute
            @html = node

        # DOM渲染完成后进行组件初始化
        @on 'renderFinished', @init

    # 组件初始化，此接口由子类实现
    init: ->

    # 渲染组件内容，此接口由子类实现
    render: ->
        ##
        # render logic...
        ##
        @emit 'renderFinished'

    # 快捷键响应
    # @param {number} kc 键码
    hotKeyResponse: (kc) ->
        console.log kc

module.exports = BaseComp
