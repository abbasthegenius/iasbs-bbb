#!/bin/bash

# Pull in the helper functions for configuring BigBlueButton
source /etc/bigbluebutton/bbb-conf/apply-lib.sh

#enableUFWRules

echo "Warning: change external_rtp_ip and external_sip_ip to the public IP of your BBB server."

echo "Running three parallel Kurento media server"
enableMultipleKurentos

echo "Make the HTML5 client default"
sed -i 's~attendeesJoinViaHTML5Client=.*~attendeesJoinViaHTML5Client=true~g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties
sed -i 's~moderatorsJoinViaHTML5Client=.*~moderatorsJoinViaHTML5Client=true~g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Set Welcome message"
sed -i 's~defaultWelcomeMessage=.*~defaultWelcomeMessage=Welcome to <b>%%CONFNAME%%</b>!~g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties
sed -i 's~defaultWelcomeMessageFooter=.*~defaultWelcomeMessageFooter=Use a <b>headset</b> to avoid causing background noise.<br>Refresh the browser in case of any network issue.<br>Help: <a target="_blank" href="https://iasbs.ac.ir/iasbs-elearn">IASBS E-Learning</a>~g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Let Moderators unmute users"
sed -i 's~allowModsToUnmuteUsers=.*~allowModsToUnmuteUsers=true~g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Enable - See other viewers webcams"
sed -i 's~webcamsOnlyForModerator=.*~webcamsOnlyForModerator=false~g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Mute the class on start"
sed -i 's~muteOnStart=.*~muteOnStart=true~g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Saves meeting events even if the meeting is not recorded"
sed -i 's~keepEvents=.*~keepEvents=true~g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Set maximum users per class to 200"
sed -i 's~defaultMaxUsers=.*~defaultMaxUsers=200~g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Enable private chat"
sed -i 's~lockSettingsDisablePrivateChat=.*~lockSettingsDisablePrivateChat=false~g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Enable public chat"
sed -i 's~lockSettingsDisablePublicChat=.*~lockSettingsDisablePublicChat=false~g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Enable shared note"
sed -i 's~lockSettingsDisableNote=.*~lockSettingsDisableNote=false~g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Enable mic";
sed -i 's~lockSettingsDisableMic=.*~lockSettingsDisableMic=false~g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Enable - See other users in the Users list"
sed -i 's~lockSettingsHideUserList=.*~lockSettingsHideUserList=false~g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Prevent viewers from sharing webcams"
sed -i 's~lockSettingsDisableCam=.*~lockSettingsDisableCam=true~g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Allow users from joining classes from multiple devices"
sed -i 's~allowDuplicateExtUserid=.*~allowDuplicateExtUserid=true~g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Disable - End the meeting when there are no moderators after a certain period of time. Prevents students from running amok."
sed -i 's~endWhenNoModerator=.*~endWhenNoModerator=false~g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "Set maximum meeting duration to 360 minutes"
sed -i 's~defaultMeetingDuration=.*~defaultMeetingDuration=360~g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "listen only mode"
sed -i 's~listenOnlyMode:.*~listenOnlyMode: true~g' /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml

echo "Audio check"
sed -i 's~skipCheck:.*~skipCheck: false~g' /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml

echo "Set Client Title"
sed -i 's~clientTitle:.*~clientTitle: IASBS~g' /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml

echo "Set App Title"
sed -i 's~appName:.*~appName: IASBS E-Learning~g' /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml

echo "Set Helplink"
sed -i 's~helpLink:.*~helpLink: http://iasbs.ac.ir/iasbs-elearn~g' /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml
