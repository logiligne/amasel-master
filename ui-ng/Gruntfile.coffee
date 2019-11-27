module.exports = (grunt)->
	grunt.initConfig({
		browserify:
			build:
				src: ['src/app.coffee']
				dest: 'app/app.js'
				options:
					browserifyOptions:
						debug: true
					transform: ['cjsxify', 'reactify']
					external: [
						'jquery',
						'collapsible',
						'classnames',
						'react' ,
						'react-addons' ,
						'react-paginate',
						'react-bootstrap',
						'pouchdb',
						'bootstrap',
						'jscroll',
					],
					exclude: ['startbootstrap-simple-sidebar']
		browserifyBower:
			build:
				options:
					debug:	true
					file: 'app/lib.js'
					forceResolve:
						'crossroads': 'dist/crossroads.js'
						'bootstrap': 'dist/js/bootstrap.js'
						'collapsible': 'jquery.collapsible.js'
						'scroll': 'jquery.jscroll.min.js'
						#'react-infinite-scroll': 'prod/scripts/infinitescroll.js'
						# metisMenu: 'dist/metisMenu.min.js',
					# shim:
					# 	jquery:
					# 		exports: '$'
					# 	metisMenu:
					# 		exports: null,
					# 		depends:
					# 			jquery: '$'
		bower_concat:
			build:
				exclude: ['metisMenu']
				dest: '/dev/null'
				cssDest: 'app/lib.css'
				mainFiles:
					'collapsible': 'jquery.collapsible.js'
					'scroll': 'jquery.jscroll.min.js'
					'startbootstrap-simple-sidebar': ['css/simple-sidebar.css']
					'db-model': ['index.coffee']
					'crossroads': ['dist/crossroads.js']
					#'react-infinite-scroll': 'prod/scripts/infinitescroll.js'
		copy:
			html:
				files: [{
						flatten: true
						expand: true
						src: ['src/*.html']
						dest: 'app/'
				},{
						flatten: true
						expand: true
						src: ['src/css/*.css']
						dest: 'app/'
				}]
			static:
				files: [{
						expand: true
						flatten: true
						src: [
							'lib/font-awesome/fonts/fontawesome-webfont.woff'
							'lib/font-awesome/fonts/fontawesome-webfont.ttf'
							'lib/bootstrap/fonts/glyphicons-halflings-regular.woff'
							'lib/bootstrap/fonts/glyphicons-halflings-regular.ttf'
						]
						dest: 'app/fonts/'
					},{
						src: ['lib/bootstrap/css/bootstrap.css.map']
						dest: 'app/'
					}]
		shell:
			'db-model':
					command: 'pushd ../db-model && grunt && popd && npm remove db-model && npm install db-model'
		watch:
			scripts:
				files: ['src/css/*.css', 'src/*.js', 'src/*.cjsx', 'src/*.coffee', 'src/components/*.js', 'src/components/*.cjsx', 'src/components/*.coffee', 'src/mixins/*.cjsx'],
				tasks: ['copy:html', 'browserify:build'],
			html:
				files: [ 'src/*.html']
				tasks: ['copy:html:build']
		couchapp:
			serve:
				options:
					appMain: 'couchapp.js'
					staticDir: 'app'
					couchUrl: 'http://localhost:5984/amasel'
			push:
				options:
					appMain: 'couchapp.js'
					couchUrl: 'http://localhost:5984/amasel'
	})
	grunt.loadNpmTasks('grunt-browserify')
	grunt.loadNpmTasks('grunt-browserify-bower') # use concat for now, as it it a lot faster
	grunt.loadNpmTasks('grunt-bower-concat')
	grunt.loadNpmTasks('grunt-contrib-copy')
	grunt.loadNpmTasks('grunt-contrib-watch')
	grunt.loadNpmTasks('grunt-couchapp-task')
	grunt.loadNpmTasks('grunt-shell')
	grunt.registerTask('default', ['browserify'])
	grunt.registerTask('build', ['browserify', 'bower_concat', "browserifyBower" ,'copy:html', 'copy:static'])
	grunt.registerTask('serve', ['couchapp:serve', 'watch'])
	grunt.registerTask('db-model', ['shell:db-model'])
