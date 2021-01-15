#!/bin/bash

export HOST_NAME=bbb.rayainst.com;

echo "Replacing default apply-conf.sh in BBB with your customized version"
cp apply-config.sh /etc/bigbluebutton/bbb-conf/apply-config.sh
chmod +x /etc/bigbluebutton/bbb-conf/apply-config.sh

echo "Change default presentation file and logo"
cp ./files/logo/favicon.ico ./files/logo/main.png ./files/logo/small.png /var/www/bigbluebutton-default/
cp ./files/logo/favicon.ico ./files/logo/small.png /var/www/bigbluebutton/client/
cp ./files/default.pdf /var/www/bigbluebutton-default/
cp small.png /var/bigbluebutton/playback/presentation/2.0/logo.png

echo "Change Max Upload File from 30M to 80M"
export MAX_F=80;
sed -i "s~maxFileSizeUpload=30000000~maxFileSizeUpload=${MAX_F}000000~g" /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties
sed -i "s~30000000~${MAX_F}000000~g" /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml
sed -i "s~30m~${MAX_F}m~g" /etc/bigbluebutton/nginx/web.nginx

echo "Change default error pages"
rm /var/www/bigbluebutton-default/*.html
cp ./files/html/*.html /usr/share/nginx/html/
cp ./files/html/index.html /var/www/bigbluebutton-default/
echo $HOST_NAME > /var/www/bigbluebutton-default/index.html
sed -i "s~elearn.iasbs.ac.ir~$HOST_NAME~g" /usr/share/nginx/html/*.html
sed -i "s~#error_page  404  /404.html;~  location / {\n    root   /var/www/bigbluebutton-default;\n    index  index.html index.htm;\n    expires 1m;\n  }~g" /etc/nginx/sites-available/bigbluebutton
sed -i "s~500 502 503 504  /50x.html~403 404 500 502 503 504 /x.html~g" /etc/nginx/sites-available/bigbluebutton
sed -i "s~root   /var/www/nginx-default;~root /usr/share/nginx/html; internal;~g" /etc/nginx/sites-available/bigbluebutton
sed -i "s~50x.html~x.html~g" /etc/nginx/sites-available/bigbluebutton

echo "Restarting bbb"
bbb-conf --restart
