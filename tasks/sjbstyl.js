/*
 * grunt-sjbstyl
 * https://github.com/evanchen/grunt-contrib-sjbstyl
 *
 * Copyright (c) 2013 evan.chen
 * Licensed under the MIT license.
 */

'use strict';

module.exports = function(grunt) {

  var nib = require('nib');
  var compileStylus = function(srcFile, options, callback) {
    options = grunt.util._.extend({filename: srcFile}, options);

    // Never compress output in debug mode
    if (grunt.option('debug')) {
      options.compress = false;
    }

    var srcCode = grunt.file.read(srcFile);
    var stylus = require('stylus');
    var s = stylus(srcCode);

    // Load Nib if available
    try {
      s.use(require('nib')()).import('nib');
    } catch (e) {}

    s.render(function(err, css) {
      if (err) {
        grunt.log.error(err);
        grunt.fail.warn('Stylus failed to compile.');

        callback(css, true);
      } else {
        callback(css, null);
      }
    });
  };

  var sty = require('./styl.js') 

  grunt.registerMultiTask('sjbstyl', 'Your task description goes here.', function() {
    // Merge task-specific and/or target-specific options with these defaults.
    var options = this.options({
      punctuation: '.',
      separator: ', '
    });

    // Iterate over all specified file groups.
    this.files.forEach(function(f) {
        sty.complies(grunt, compileStylus).init(options);
    });
  });

  
};
