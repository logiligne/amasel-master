var	http = require('http'),
		connect = require('connect'),
		compression = require('compression'),
		morgan = require('morgan'),
		httpProxy = require('http-proxy');

var port = 8012;

var proxy = httpProxy.createProxyServer({
	target: 'http://localhost:5984/'
});

proxy.on('error', function(e) {
  console.error(e);
});

var app = connect();

//app.use(morgan('combined'));

app.use(compression());
app.use(
	function(req, res) {
		//console.log("Got req")
		proxy.web(req, res);
	}
).listen(port);

console.log('proxy  started  on port ' +  port);
