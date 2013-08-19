module.exports = (grunt) ->

  grunt.initConfig
    coffee:
      modules:
        options:
          bare: true
        expand: true
        flatten: true
        src: ['assets/js/*.coffee']
        dest: 'public/js/'
        ext: '.js'

    watch:
      coffee:
        files: ['assets/**/*.coffee']
        tasks: ['coffee']

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'default', ['coffee']