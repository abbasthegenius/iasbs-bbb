#!/bin/bash

# Pull in the helper functions for configuring BigBlueButton
source /etc/bigbluebutton/bbb-conf/apply-lib.sh

enableUFWRules


echo "Make the HTML5 client default"
sed -i 's/attendeesJoinViaHTML5Client=.*/attendeesJoinViaHTML5Client=true/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties
sed -i 's/moderatorsJoinViaHTML5Client=.*/moderatorsJoinViaHTML5Client=true/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Set Welcome message"
sed -i 's/defaultWelcomeMessage=.*/defaultWelcomeMessage=Welcome to <b>\%\%CONFNAME\%\%<\/b>\!/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties
sed -i 's/defaultWelcomeMessageFooter=.*/defaultWelcomeMessageFooter=Use a headset to avoid causing background noise.<br>Refresh the browser in case of any network issue./g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties
#sed -i 's/defaultWelcomeMessageFooter=.*/defaultWelcomeMessageFooter=To join this meeting by phone, dial:<br>  %%DIALNUM%%<br>Then enter %%CONFNUM%% as the conference PIN number./g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

#echo "Set dial in number"
#sed -i 's/defaultDialAccessNumber=.*/defaultDialAccessNumber=+12564725575/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Let Moderators unmute users"
sed -i 's/allowModsToUnmuteUsers=.*/allowModsToUnmuteUsers=true/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Set maximum users per class to 100"
sed -i 's/defaultMaxUsers=.*/defaultMaxUsers=100/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Disable private chat"
sed -i 's/lockSettingsDisablePrivateChat=.*/lockSettingsDisablePrivateChat=true/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Disable public chat"
sed -i 's/lockSettingsDisablePublicChat=.*/lockSettingsDisablePublicChat=true/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Disable shared note"
sed -i 's/lockSettingsDisableNote=.*/lockSettingsDisableNote=true/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Prevent viewers from sharing webcams"
sed -i 's/lockSettingsDisableCam=.*/lockSettingsDisableCam=true/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Prevent users from joining classes from multiple devices"
sed -i 's/allowDuplicateExtUserid=.*/allowDuplicateExtUserid=false/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Set maximum meeting duration to 120 minutes"
sed -i 's/defaultMeetingDuration=.*/defaultMeetingDuration=120/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "No listen only mode"
sed -i 's/listenOnlyMode:.*/listenOnlyMode: false/g' /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml

echo "No audio check"
sed -i 's/listenOnlyMode:.*/skipCheck: true/g' /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml

echo "Set Client Title"
sed -i 's/clientTitle:.*/clientTitle: Class++/g' /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml

echo "Set App Title"
sed -i 's/appName:.*/appName: Class++/g' /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml

echo "Set Copyright"
sed -i 's/copyright:.*/copyright: "©2020 HigherEdLab.com"/g' /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml

echo "Set Helplink"
sed -i 's/helpLink:.*/helpLink: http:\/\/higheredlab.com\/bigbluebutton-guide#using-bigbluebutton/g' /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml

echo "Fix for 1007 and 1020 - In external.xml set ext-rtp-ip and vars.xml - https://github.com/manishkatyan/bbb-optimize#fix-1007-and-1020-errors"
echo "Have you changed Public IP of your BBB server mentioned in external_rtp_ip and external_sip_ip in apply-config.sh? Otherwise you will face issues."
xmlstarlet edit --inplace --update '//profile/settings/param[@name="ext-rtp-ip"]/@value' --value "\$\${external_rtp_ip}" /opt/freeswitch/conf/sip_profiles/external.xml
xmlstarlet edit --inplace --update '//profile/settings/param[@name="ext-sip-ip"]/@value' --value "\$\${external_sip_ip}" /opt/freeswitch/conf/sip_profiles/external.xml

xmlstarlet edit --inplace --update '//X-PRE-PROCESS[@cmd="set" and starts-with(@data, "external_rtp_ip=")]/@data' --value "external_rtp_ip=178.63.82.13" /opt/freeswitch/conf/vars.xml
xmlstarlet edit --inplace --update '//X-PRE-PROCESS[@cmd="set" and starts-with(@data, "external_sip_ip=")]/@data' --value "external_sip_ip=178.63.82.13" /opt/freeswitch/conf/vars.xml
