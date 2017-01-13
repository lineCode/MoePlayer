##
# Dev auto-flow
# Author: VenDream
# E-mail: yeshenxue@qq.com
# Update: 2017-1-13 16:38:23
##

fs = require 'fs'
gulp = require 'gulp'
run = require 'gulp-run'
clean = require 'gulp-clean'
coffee = require 'gulp-coffee'
less = require 'gulp-less'
browserify = require 'gulp-browserify'
extReplace = require 'gulp-ext-replace'
uglifyJs = require 'gulp-uglify'
uglifyCss = require 'gulp-uglifycss'
sequence = require 'run-sequence'
electron = (require 'electron-connect').server.create()

config = require './config'
rI = config.release
env = config.env
packDir = "#{rI.appName}-#{rI.platform}-#{rI.arch}"
releaseDir = "#{rI.appName}_v#{rI.appVer}"
eFunc = () ->

# Some paths 
paths = {
    dist: 'dist'                               # dist
    lessSrc: ['src/less/**/**.less']           # less src
    lessDist: 'dist/css'                       # less dist
    coffeeSrc: ['src/coffee/**/**.coffee']     # coffee
    coffeeDist: 'dist/js'                      # coffee dist
}

# Clean all
gulp.task 'cleanAll', () ->
    gulp.src [paths.dist, releaseDir, packDir], { read: false }
        .pipe clean({ force: true })

# Clean temp
gulp.task 'cleanTemp', () ->
    gulp.src [paths.dist], { read: false }
        .pipe clean({ force: true })

# Coffee -> Javascript
gulp.task 'coffee', () ->
    js = gulp.src paths.coffeeSrc, { read: false }
            .pipe browserify {
                debug: false,
                transform: ['coffeeify'],
                extensions: ['.coffee']
            }
            .pipe extReplace '.js'

    if env is 'production'
        js.pipe(uglifyJs()).pipe gulp.dest paths.coffeeDist
    else
        js.pipe gulp.dest paths.coffeeDist

# Less -> CSS
gulp.task 'less', () ->
    css = gulp.src paths.lessSrc
            .pipe less()

    if env is 'production'
        css.pipe(uglifyCss()).pipe gulp.dest paths.lessDist
    else
        css.pipe gulp.dest paths.lessDist

# Start Electron
gulp.task 'server', () ->
    electron.start()

# Reload Electron
gulp.task 'reload', () ->
    electron.reload()

# Restart Electron
gulp.task 'restart', () ->
    electron.restart()

# Run electron-packager CMD
gulp.task 'packCMD', () ->
    appName = rI.appName
    copyright = rI.copyright
    platform = rI.platform
    arch = rI.arch
    appVer = rI.appVer
    packVer = rI.packVer
    icon = rI.icon
    packCmd = "electron-packager . #{appName} --platform=#{platform} \
           --arch=#{arch} --version=#{packVer} --asar --app-version=#{appVer} \
           --app-copyright=#{copyright} --icon=#{icon} --overwrite \
           --ignore=node_modules/ --ignore=download/ --ignore=src/ --ignore=config.example.js \
           --ignore=.gitignore --ignore=.jshintrc --ignore=config.example.js \
           --ignore=gulpfile.coffee --ignore=README.md"

    run(packCmd).exec()

# Run rename CMD
gulp.task 'renameCMD', () ->
    renameCmd = "mv #{packDir} #{releaseDir}"
    run(renameCmd).exec()

# Show release success info
gulp.task 'releaseStatus', () ->
    console.log '---------------------------------------------'
    console.log "Done...! See #{releaseDir}/ for more details."
    console.log '---------------------------------------------'

# Watch files
gulp.task 'watch', () ->
    gulp.watch ['main.js'], ['restart']

    gulp.watch ['config.js'], ->
        sequence('coffee', 'restart')
    
    gulp.watch paths.coffeeSrc, ->
        sequence('coffee', 'reload')

    gulp.watch paths.lessSrc, ->
        sequence('less', 'reload')

    gulp.watch ['index.html'], ['reload']

#--------------------------------------------------------------

# Default
gulp.task 'default', () ->
    sequence(
        'cleanAll',
        'coffee',
        'less',
        'server',
        'watch'
    )

# Release
gulp.task 'release', () ->
    sequence(
        'cleanAll',
        'coffee',
        'less',
        'packCMD',
        'renameCMD',
        'cleanTemp',
        'releaseStatus'
    )
