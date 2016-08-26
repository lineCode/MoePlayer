##
# 配置自动化流程
# Author: VenDream
# E-mail: yeshenxue@qq.com
# Update: 2016-8-26 18:12:41
##

options = {
    verbose: false
}

# 引入自动化工具
fs = require 'fs'
gulp = require 'gulp'
run = require 'gulp-run'
clean = require 'gulp-clean'
coffee = require 'gulp-coffee'
less = require 'gulp-less'
browserify = require 'gulp-browserify'
livereload = require 'gulp-livereload'
extReplace = require 'gulp-ext-replace'
uglify = require 'gulp-uglify'
uglifycss = require 'gulp-uglifycss'
sequence = require 'run-sequence'
electron = (require 'electron-connect').server.create(options)

rI = require('./config').release

# 定义项目相关路径
paths = 
    # 打包用的目录
    app: 'app/'
    # 第三方库
    lib: ['lib/**/*']
    # 编译后的发布代码
    dist: ['dist/**/*']
    # 静态文件(主要为图片)
    assets: ['assets/**/*']
    # 视图文件(HTML)
    views: ['./*.html']
    # less源码
    lessSrc: ['src/less/**/**.less']
    # coffee源码
    coffeeSrc: ['src/coffee/**/**.coffee']

# 错误打印
logError = (e) ->
    console.log e

# 清理文件
gulp.task 'cleanAll', ->
    gulp.src ['app/'], {read: false}
        .pipe clean({force: true})
    gulp.src ['dist/'], {read: false}
        .pipe clean({force: true})
    gulp.src ['release'], {read: false}
        .pipe clean({force: true})

# 清理中间过程文件
gulp.task 'cleanTemp', ->
    gulp.src ['app/'], {read: false}
        .pipe clean({force: true})
    gulp.src ['dist/'], {read: false}
        .pipe clean({force: true})


# 把coffee文件编译为js文件
gulp.task 'coffee', ->
    gulp.src paths.coffeeSrc, {read: false}
        .pipe browserify
            debug: false,
            transform: ['coffeeify'],
            extensions: ['.coffee'],
        .on 'error', logError
        .pipe extReplace '.js'
        .pipe uglify()
        .pipe gulp.dest 'dist/js'
        # .pipe livereload()

# 把less文件编译为css文件
gulp.task 'less', ->
    gulp.src paths.lessSrc
        .pipe less()
        .pipe uglifycss()
        .on 'error', logError
        .pipe gulp.dest 'dist/css'
        # .pipe livereload()

# 启动electron服务
gulp.task 'server', ->
    electron.start()

# 重新装载文件
gulp.task 'reload', ->
    electron.reload()

# 重新启动electron进程
gulp.task 'restart', ->
    electron.restart()

# 转移文件
gulp.task 'copyFiles', ->
    # 转移assets
    gulp.src paths.assets, {base: './'}
        .pipe gulp.dest paths.app

    # 转移lib文件
    gulp.src paths.lib, {base: './'}
        .pipe gulp.dest paths.app

    # 转移编译后的代码
    gulp.src paths.dist, {base: './'}
        .pipe gulp.dest paths.app

    # 转移入口文件及配置文件
    gulp.src ['main.js', 'config.js']
        .pipe gulp.dest paths.app

    # 转移其他文件
    gulp.src ['index.html', 'package.json', 'LICENSE', 'README.md']
        .pipe gulp.dest paths.app
    gulp.src [
        'node_modules/underscore/**/*', 
        'node_modules/devtron/**/*',
        'node_modules/electron-connect/**/*'
    ], {base: './'}
        .pipe gulp.dest paths.app

# 运行打包命令
gulp.task 'packCMD', ->
    appName = rI.appName
    copyright = rI.copyright
    platform = rI.platform
    arch = rI.arch
    appVer = rI.appVer
    packVer = rI.packVer
    icon = rI.icon

    packCmd = "electron-packager #{paths.app} #{appName} --platform=#{platform} \
           --arch=#{arch} --version=#{packVer} --asar --app-version=#{appVer} \
           --app-copyright=#{copyright} --icon=#{icon} --overwrite"

    run(packCmd).exec()

# 运行重命名命令
gulp.task 'renameCMD', ->
    packDir = "#{rI.appName}-#{rI.platform}-#{rI.arch}"
    releaseDir = 'release'
    renameCmd = "mv #{packDir} #{releaseDir}"

    run(renameCmd).exec()

# 监听文件改动
gulp.task 'watch', ->
    gulp.watch ['main.js', 'config.js'], ['restart']
    
    gulp.watch paths.coffeeSrc, ->
        sequence('coffee', 'reload')

    gulp.watch paths.lessSrc, ->
        sequence('less', 'reload')

    gulp.watch ['index.html'], ['reload']

#--------------------------------------------------------------

# 默认任务流程
gulp.task 'default', ->
    sequence(
        'cleanAll',
        'coffee',
        'less',
        'server',
        'watch'
    )

# 打包发布
gulp.task 'package', ->
    sequence(
        'cleanAll',
        'coffee',
        'less',
        'copyFiles',
        'packCMD',
        'renameCMD',
        'cleanTemp'
    )
