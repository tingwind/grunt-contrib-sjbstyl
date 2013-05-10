 #!/usr/bin/env node

exports.complies = (grunt, compe) ->
  exports = {}
  exports.init = (options) ->

    fs = require 'fs'
    path= require 'path'
    opt = require 'optimist'
    stylus = require 'stylus'
    nib = require 'nib'

    # 给上线部署只编译stylus预留接口
    getPath = (dir) ->
      if options.onlyStylu
        return dir
      else
        return 'tos-styl/' + dir

    distCss = getPath 'dist_css'
    distStyl = getPath 'dist_styl'

    importPath = getPath 'styl/import'
    basePath = getPath 'styl/base'
    dplPath = getPath 'styl/dpl'
    sysPath = getPath 'styl/sys'
    pagePath = getPath 'styl/app/page'

    writeFile = (putfile, results) ->
      grunt.file.write putfile, results.join grunt.util.normalizelf grunt.util.linefeed

    #获取到指定目录下的文件名列表
    processDir = (dir, callback) ->
      grunt.file.recurse dir, (abspath, rootdir, subdir, filename) ->
        #line = '@import ' + '"' + abspath + '"'
        callback filename, abspath

    tasks =
      importDirProcess: (mod, needimp = false, currentDir) ->
        putfile = distStyl + '/' + mod + '.styl'
        putCss = distCss + '/' + mod + '.css'
        content = []
        linesArr = []
        filesArr = []
        fargs = []
        #是不是要引入import.styl
        if needimp is true
          fargs.push ->
            content.push grunt.file.read distStyl + '/import.styl'
        #遍历目录下的所有文件，写成一句一句的import
        fargs.push ->
          processDir currentDir, (filename, abspath) ->
            linesArr[filename]= path: '@import ' + '"' + abspath + '"'
            filesArr.push filename
        fargs.push ->
            filesArr.sort()
            content.push linesArr[file].path for file in filesArr
        #把所有的import 语句写入的目标styl文件中
        fargs.push ->
          writeFile putfile, content
        #调用compile把stylu编译成css
        fargs.push ->
          compe putfile, options, (css, err) ->
            grunt.file.write putCss, css
        grunt.util.async.parallel fargs
      proPage: (filepath) ->
        pathArr = filepath.split('/')
        putfile = distStyl + '/' + pathArr[pathArr.length - 1]
        nameArr = pathArr[pathArr.length - 1].split('.')
        nameArr.pop()
        name = nameArr.join('.')
        putCss = distCss + '/' + name + '.css'
        content = []
        fargs = []
        fargs.push ->
          tasks.importDirProcess 'import', false, importPath
        fargs.push ->
          content.push grunt.file.read distStyl + '/import.styl'
        fargs.push ->
          content.push grunt.file.read filepath
        fargs.push ->
          writeFile putfile, content
        fargs.push ->
          compe putfile, options, (css, err) ->
            grunt.file.write putCss, css
        grunt.util.async.parallel fargs

    if options.mod in ['base', 'dpl', 'sys']
      currentDir = path.dirname options.filepath
      fargs = []
      fargs.push ->
        tasks.importDirProcess 'import', false, importPath
      fargs.push ->
        tasks.importDirProcess options.mod, true, currentDir
      grunt.util.async.parallel fargs
    else if options.mod is 'import'
      currentDir = path.dirname options.filepath
      fargs = []
      fargs.push ->
        tasks.importDirProcess options.mod, false, currentDir
      fargs.push ->
        tasks.importDirProcess 'base', true, basePath
      fargs.push ->
        tasks.importDirProcess 'dpl', true, dplPath
      fargs.push ->
        tasks.importDirProcess 'sys', true, sysPath
      fargs.push ->
        grunt.file.recurse pagePath, (abspath, rootdir, subdir, filename) ->
          tasks.proPage abspath
      grunt.util.async.parallel fargs
    else if options.mod is 'page'
      tasks.proPage options.filepath
    else if options.mod is 'module'
      grunt.file.recurse pagePath, (abspath, rootdir, subdir, filename) ->
        tasks.proPage abspath

  return exports
