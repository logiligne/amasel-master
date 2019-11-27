	npm install bower-requirejs

------------

	npm install couchapp

  OR

	npm install https://github.com/mikeal/node.couchapp.js/archive/master.tar.gz

------------

	npm install https://github.com/zaro/connect-compiler/archive/master.tar.gz

  OR

	npm install connect-compiler

------------

Buildging one js file:

    npm install -g requirejs

go to js/

		coffee -c .

and then run :

		r.js -o name=main out=main-built.js baseUrl=. mainConfigFile=require.config.js optimize=none
