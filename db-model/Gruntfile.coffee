module.exports = (grunt)->
	grunt.initConfig({
		coffee:
			compile:
				expand: true,
				flatten: true,
				src: ['src/*.coffee'],
				dest: 'build/',
				ext: '.js'
		watch:
			scripts:
				files: ['src/*.coffee'],
				tasks: ['coffee:compile'],
		mochaTest:
			test:
				options: {
					reporter: 'spec',
					require: 'coffee-script/register'
				},
				src: ['test/**/*.coffee']
	})
	grunt.loadNpmTasks('grunt-contrib-coffee')
	grunt.loadNpmTasks('grunt-contrib-watch')
	grunt.loadNpmTasks('grunt-mocha-test')
	grunt.registerTask('default', ['coffee'])
	grunt.registerTask('test', ['mochaTest'])
