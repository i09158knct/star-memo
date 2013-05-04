path = require 'path'

module.exports = (grunt) ->
  grunt.initConfig
    regarde:
      livereload:
        files: [
          'public/**/*'
          'assets/**/*'
          'views/**/*'
        ]
        tasks: ['livereload']

    livereload:
      port: 35729

    exec:
      server: command: [
        'nodemon server.coffee'
        '-w models'
        '-w routes'
        '-w lib'
        '-w server.coffee'
        '-d 0'
        '&'
      ].join ' '



  [
    'grunt-exec'
    'grunt-regarde'
    'grunt-contrib-livereload'
  ].forEach grunt.loadNpmTasks

  grunt.registerTask 'copy-components', ->
    assets =
      'assets/js/vender': [
        'components/bootstrap/docs/assets/js/bootstrap.min.js'
        'components/backbone/backbone.js'
        'components/underscore/underscore.js'
        'components/jquery/jquery.js'
        'components/mousetrap/mousetrap.js'
      ]
      'assets/css/vender': [
        'components/bootstrap/docs/assets/css/bootstrap.css'
      ]
      'public/img': [
        'components/bootstrap/docs/assets/img/glyphicons-halflings.png'
        'components/bootstrap/docs/assets/img/glyphicons-halflings-white.png'
      ]

    for pathName, sources of assets
      grunt.file.mkdir pathName
      for source in sources
        fileName = path.basename source
        grunt.log.writeln "copying #{fileName}"
        grunt.file.copy source, "#{pathName}/#{fileName}"


  grunt.registerTask 'init', [
    'copy-components'
  ]

  grunt.registerTask 'server', [
    'exec:server'
  ]

  grunt.registerTask 'default', [
    'livereload-start'
    'server'
    'regarde'
  ]
