# Installing Amasel Helper

## Requirements

1. Linux server with Nginx, Couchdb 2.X , Nodejs v0.12.X , CoffeeScript 1.9.1, couchapp and certbot installed
  - Couchdb:  https://couchdb.apache.org/
  - Nodejs: https://nodejs.org/en/download/releases/
  - couchapp : https://github.com/zaro/node.couchapp.js
  - cofeescript 1.9.1: https://coffeescript.org/v1/
  - https://certbot.eff.org/


## Installation

1. Create new admin user and password for Couchdb ( check  https://docs.couchdb.org/en/stable/intro/security.html)
2. Clone this repo somewhere : git clone <this repo> /srv/mynewshop
3. edit `worker/config.coffee` and put the correct Amazon Credentials and database, choose some name for the database e.g. `mynewshop`
4. create the database :

    cd worker/
    npm install
    coffee db_create.coffee

5. Install and the syncronization service:

    cd systemd/
    ./gen_unit.sh
    cp mynewshop.service /etc/systemd/system
    systemctl daemon-reload
    systemctl start mynewshop.service
    systemctl enable mynewshop.service

6. Install ui:

    cd ui/
    npm install
    couchapp push app.js http://<admin user>:<admin password>@localhost:5984/mynewshop

7. Setup a vhost for couchdb:
  in /opt/couchdb/etc/local.ini make sure to add for example:

```
[vhosts]
mynewshop.example.com = /mynewshop/_design/app/_rewrite

```

8. Install gzip proxy:

    cd frontend-proxy/
    npm install

then create  /etc/systemd/system/amasel-proxy.service  like so

```
[Unit]
Description=Amasel systemd wrapper for run_amasel_proxy.sh
Requires=network-online.target
After=network-online.target

[Service]
ExecStart={{{ path to cloned reposotory }}}}/frontend-proxy/run_amasel_proxy.sh
Restart=always

[Install]
WantedBy=multi-user.target
```

and do :

    systemctl enable amasel-proxy.service
    systemctl start amasel-proxy.service

9. Configure nginx reverse proxy like so:

```
upstream funnyjunk-couchdb-gz {
      server localhost:8012;
}


server {
    listen       443 ssl;
    server_name mynewshop.example.com;

    access_log  /var/log/nginx/mynewshop.example.com.log;
    error_log  /var/log/nginx/mynewshop.example.com.error.log;
    root   /usr/share/nginx/html;
    index  index.html index.htm;

    ssl_prefer_server_ciphers On;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS;


    #this is to avoid Request Entity Too Large error
    client_max_body_size 1024M;

    location / {
     proxy_pass  http://funnyjunk-couchdb-gz;
     proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
     proxy_redirect off;
     proxy_buffering off;
     proxy_set_header        Host            $host;
     proxy_set_header        X-Real-IP       $remote_addr;
     proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
     proxy_set_header        Strict-Transport-Security "max-age=16070400; includeSubDomains" ;
   }

    ssl_certificate /etc/letsencrypt/live/mynewshop.example.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/mynewshop.example.com/privkey.pem; # managed by Certbot
}
```

10. Run certbot to generate certificates