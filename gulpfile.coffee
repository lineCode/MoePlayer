##
# 配置自动化流程
# Author: VenDream
# E-mail: yeshenxue@qq.com
# Update: 2016-7-16 16:09:33
##

# 全局定义
options = {
	verbose: true
}

# 引入自动化工具
gulp = require 'gulp'
del = require 'del'
coffee = require 'gulp-coffee'
less = require 'gulp-less'
browserify = require 'gulp-browserify'
livereload = require 'gulp-livereload'
extReplace = require 'gulp-ext-replace'
uglify = require 'gulp-uglify'
uglifycss = require 'gulp-uglifycss'
sequence = require 'gulp-sequence'
electron = (require 'electron-connect').server.create(options)

# 定义项目相关路径
paths = 
	# 第三方库
	lib: ['lib/**/*']
	# 编译压缩后的发布代码
	dist: ['dist/**/*']
	# 视图文件(HTML)
	views: ['./*.html']
	# 静态文件(主要为图片)
	assets: ['assets/**/*']
	# less源码
	lessSrc: ['src/less/**/**.less']
	# coffee源码
	coffeeSrc: ['src/coffee/**/**.coffee']

# 错误打印
logError = (e) ->
	console.log e

# 清空缓存文件夹
gulp.task 'clean', ->
	del.sync 'dist'
	return

# 把coffee文件编译为js文件
gulp.task 'coffee', ->
	del.sync 'dist/js'
	gulp.src paths.coffeeSrc, {read: false}
		.pipe browserify
			debug: false,
			transform: ['coffeeify'],
			extensions: ['.coffee']
		.on 'error', logError
		.pipe extReplace '.js'
		.pipe uglify()
		.pipe gulp.dest 'dist/js'
		.pipe livereload()

	return

# 把less文件编译为css文件
gulp.task 'less', ->
	del.sync 'dist/css'
	gulp.src paths.lessSrc
		.pipe less()
		.pipe uglifycss()
		.on 'error', logError
		.pipe gulp.dest 'dist/css'
		.pipe livereload()

	return

# 启动electron服务
gulp.task 'server', ->
	electron.start()
	gulp.watch 'main.js', ['restart']

	return

# 重新装载文件
gulp.task 'reload', ->
	electron.reload()

	return

# 重新启动electron进程
gulp.task 'restart', ->
	electron.restart()

	return

# 监听文件改动
gulp.task 'watch', ->
	livereload.listen()
	gulp.watch paths.coffeeSrc, ['coffee', 'reload']
	gulp.watch paths.lessSrc, ['less', 'reload']
	gulp.watch paths.views, ['reload']

	return

# 默认任务流程
gulp.task 'default', sequence(
	'clean', 
	[
		'coffee', 
		'less'
	],
	'server',
	'watch'
)
