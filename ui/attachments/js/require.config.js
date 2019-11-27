require.config({
  shim: {
    'angular-sanitize': {
      deps: [
        'angular'
      ]
    },
    'angular-ui': {
      deps: [
        'angular'
      ]
    },
    'angular-bootstrap': {
      deps: [
        'angular'
      ]
    },
    select2: {
      deps: [
        'jquery'
      ]
    },
    pdfmake: {
      deps: [
        'vfs_fonts'
      ],
      exports: 'pdfmake'
    }
  },
  paths: {
    angular: 'lib/angular/angular',
    'angular-sanitize': 'lib/angular-sanitize/angular-sanitize',
    assert: 'lib/assert/assert',
    blanket: 'lib/blanket/dist/qunit/blanket',
    couchr: 'lib/couchr/couchr-browser',
    jquery: 'lib/jquery/jquery',
    jsPDF: 'lib/jspdf/dist/jspdf.min',
    modernizr: 'lib/modernizr/modernizr',
    select2: 'lib/select2/select2',
    underscore: 'lib/underscore/underscore',
    'underscore.string': 'lib/underscore.string/dist/underscore.string',
    'angular-bootstrap': 'lib/angular-bootstrap/ui-bootstrap-tpls.min',
    events: 'lib/events/events',
    querystring: 'lib/querystring/querystring.min',
    'angular-ui': 'lib/angular-ui/build/angular-ui',
    pdfmake: 'lib/pdfmake/build/pdfmake',
    vfs_fonts: 'lib/pdfmake/build/vfs_fonts',
    'pdfkit-0.7.0': 'lib/bower-pdfkit/pdfkit-0.7.0',
    'blob-stream-v0.1.2': 'lib/bower-pdfkit/blob-stream-v0.1.2',
    handlebars: 'lib/handlebars/handlebars.amd'
  },
  map: {
    '*': {
      pdfkit: 'pdfkit-0.7.0',
      'blob-stream': 'blob-stream-v0.1.2'
    }
  },
  baseUrl: 'js/',
  deps: ['main'],
  waitSeconds: 180
});
