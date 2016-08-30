##
# 设置面板组件
# @Author VenDream
# @Update 2016-8-30 18:17:04
##

BaseComp = require './BaseComp'

class SettingPanel extends BaseComp
    constructor: (selector, eventBus) ->
        super selector, eventBus

    init: ->
        @panel = @html.querySelector '.settingPanel'
        @backBtn = @html.querySelector '.back-btn'

        @sType = @html.querySelector '.setting-type'
        @sDetail = @html.querySelector '.setting-detail'

        @close()
        @eventBinding()

    render: ->
        htmls = 
            """
            <div class="settingPanel">
                <div class="back-btn">
                </div>
                <div class="setting-type">
                    <ul>
                        <li class="not-select selected">常规</li>
                        <li class="not-select">音质</li>
                        <li class="not-select">下载</li>
                        <li class="not-select">关于</li>
                    </ul>
                </div>
                <div class="setting-detail">
                    <div class="detail normal-setting">
                        常规设置
                    </div>
                    <div class="detail quality-setting hidden">
                        音质设置
                    </div>
                    <div class="detail download-setting hidden">
                        下载设置
                    </div>
                    <div class="detail about hidden">
                        关于
                    </div>
                </div>
            </div>
            """

        @html.innerHTML = htmls
        @emit 'renderFinished'

    eventBinding: ->
        # 返回
        $(@backBtn).on 'click', (e) =>
            @close()

        # 选择类型
        $(@sType).find('li').on 'click', (e) =>
            $(e.target).siblings('li').removeClass 'selected'
            $(e.target).addClass 'selected'

            idx = $(e.target).index()
            $targetTab = $(@sDetail).find('.detail').eq idx

            $targetTab.siblings('.detail').addClass 'hidden'
            $targetTab.removeClass 'hidden'

    #---------------------------------------------------
    #                     对外接口
    #---------------------------------------------------

    # 打开面板
    open: ->
        $c = $(@panel).parent('.settingPanel-c')
        $c.length > 0 and $c.fadeIn 0

    # 关闭面板
    close: ->
        $c = $(@panel).parent('.settingPanel-c')
        $c.length > 0 and $c.fadeOut 0

module.exports = SettingPanel
