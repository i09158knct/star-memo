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

      test:
        files: [
          'controllers/**/*'
          'models/**/*'
          'tasks/**/*'
          'test/**/*'
          'server.coffee'
        ]
        tasks: ['test']


    simplemocha:
      options:
        reporter: 'spec'
        compilers: ['coffee:coffee-script']
      all: ['test/**/*.coffee']


    livereload:
      port: 35729


    exec:
      base_command: [
        'nodemon server.coffee'
        '-w controllers'
        '-w models'
        '-w lib'
        '-w server.coffee'
        '-d 0'
      ].join ' '

      server: command: '<%= exec.base_command %>'
      server_background: command: '<%= exec.base_command %> &'



  grunt.loadNpmTasks task for task in [
    'grunt-exec'
    'grunt-simple-mocha'
    'grunt-regarde'
    'grunt-contrib-livereload'
  ]



  grunt.registerTask 'copy-components', ->
    (
      grunt.file.mkdir pathName
      for source in sources
        fileName = path.basename source
        grunt.log.writeln "copying #{fileName}"
        grunt.file.copy source, "#{pathName}/#{fileName}"

    ) for pathName, sources of {
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
    }



  grunt.registerTask name, targets for name, targets of {
    'initialize': ['copy-components']
    'server': ['exec:server']
    'test': ['simplemocha']
    'default': [
      'livereload-start'
      'exec:server_background'
      'regarde'
    ]
  }

