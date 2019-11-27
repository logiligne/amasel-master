 var couchapp = require('couchapp')
  , path = require('path')
  ;

ddoc = 
  { _id:'_design/app'
  , rewrites : 
    [ {from:"/", to:'index.html'}
    , {from:"/session", to:'../../../_session'}
    , {from:"/users/*", to:'../../../_users/*'}
    , {from:"/*", to:'*'}
    ]
  }
  ;

ddoc.views = {};

couchapp.loadAttachments(ddoc, path.join(__dirname, 'attachments'));

module.exports = ddoc;