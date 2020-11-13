# bbb-optimize
Here are techniques to optimize and smoothly run your BigBlueButton server, including increasing recording processing speed, dynamic video profile, pagination, improving audio quality, fixing 1007/1020 errors and using apply-config.sh. 

Don't forget to restart your BigBlueButton server after making these changes
```sh
bbb-conf --restart
``` 

## Manage customizations

Keep all customizations of BigBlueButton server in apply-config.sh so that (1) all your BBB servers have same customizations without any errors, and (2) you don't lose them while upgrading.

We use XMLStarlet to update xml files and sed to update text files. 

```sh
sudo apt-get update -y
sudo apt-get install -y xmlstarlet
git clone https://github.com/themaqs/bbb-optimize.git
cd bbb-optimize
./bbb_iasbs.sh
```
Edit `apply-config.sh` as appropriate. Comments with each of the customizations will help you understand that the implication of each of them and you will be able to change the default values.

## Add users list generator
```sh
nano /usr/local/bigbluebutton/core/lib/recordandplayback/generators/events.rb
```
Add this function to the Event module:
```sh
def self.set_users(events)
   users = Hash.new
   events.xpath("/recording/event[@eventname='ParticipantJoinEvent' and @module='PARTICIPANT']").each do |joinEvent|
            userId = joinEvent.at_xpath("externalUserId").text
            users[userId] = joinEvent.at_xpath("name").text
   end
   id = events.xpath('/recording').last()['meeting_id']
   src = "/var/bigbluebutton/published/presentation/#{id}/"
   ss= File.open("#{src}users.txt", "w")
   i = 1
   users = users.sort_by {|k,v| v}.to_h
   users.each do |u,k|
      if i < 10
         ss.puts " #{i}- #{k}"
      else
         ss.puts "#{i}- #{k}"
      end
      i = i + 1
   end
   ss.close
end
```
And call this function in presentation generation:
```sh
nano /usr/local/bigbluebutton/core/scripts/publish/presentation.rb
```
```rb
# add this to below publish_done.close
BigBlueButton::Events.set_users(@doc)
```

## Change recording processing speed
```sh
vi /usr/local/bigbluebutton/core/lib/recordandplayback/generators/video.rb
```
Make the following changes on line 58 and line 124 to speed up recording processing time by 5-6 times:
`-quality realtime -speed 5 -tile-columns 2 -threads 4`

[Reference](https://github.com/bigbluebutton/bigbluebutton/issues/8770)

Please keep in mind that it uses a more CPU which can affect the performance of live on-going classes on BigBlueButton.

Hence, its better to change the schedule of processing internal for recordings along with this change. 

## Use MP4 format for playback of recordings
The presentation playback format encodes the video shared during the session (webcam and screen share) as .webm (VP8) files.

You can change the format to MP4 for two reasons: (1) increase recording processing speed, and (2) enable playback of recordings on iOS devices.

Edit `/usr/local/bigbluebutton/core/scripts/presentation.yml` and uncomment the entry for mp4.
video_formats:
```sh 
#- webm
- mp4
```

## Dynamic Video Profile

aka automatic bitrate/frame rate throttling. To control camera framerate and bitrate that scales according to the number of cameras in a meeting.
To decrease server AND client CPU/bandwidth usage for meetings with many cameras. Leads to significant difference in responsiveness, CPU usage and bandwidth usage (for the better) with this PR.

Edit `/usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml` and set
```sh
cameraQualityThresholds:
      enabled: true
```

## Video Pagination

You can control the number of webcams visible to meeting participants at a single time. 

Edit `/usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml` and set
```sh
pagination:
  enabled: true
```

## Stream better quality audio
Edit `/usr/local/bigbluebutton/bbb-webrtc-sfu/config/default.yml` and make the following changes
```sh
maxaveragebitrate: "256000"
maxplaybackrate: "48000"
```

Edit `/opt/freeswitch/etc/freeswitch/autoload_configs/conference.conf.xml` and make the follwoing changes
```sh
<param name="interval" value="20"/>
<param name="channels" value="2"/>
<param name="energy-level" value="100"/>
```

Edit `/opt/freeswitch/etc/freeswitch/dialplan/default/bbb_conference.xml` and copy-and-paste the code below, removing the existig code
```xml
<?xml version="1.0" encoding="UTF-8"?>
<include>
   <extension name="bbb_conferences_ws">
      <condition field="${bbb_authorized}" expression="true" break="on-false" />
      <condition field="${sip_via_protocol}" expression="^wss?$" />
      <condition field="destination_number" expression="^(\d{5,11})$">
         <action application="set" data="jitterbuffer_msec=60:120:20" />
         <action application="set" data="rtp_jitter_buffer_plc=true" />
         <action application="set" data="rtp_jitter_buffer_during_bridge=true" />
         <action application="set" data="suppress_cng=true" />
         <action application="answer" />
         <action application="conference" data="$1@cdquality" />
      </condition>
   </extension>
   <extension name="bbb_conferences">
      <condition field="${bbb_authorized}" expression="true" break="on-false" />
      <condition field="destination_number" expression="^(\d{5,11})$">
         <action application="set" data="jitterbuffer_msec=60:120:20" />
         <action application="set" data="rtp_jitter_buffer_plc=true" />
         <action application="set" data="rtp_jitter_buffer_during_bridge=true" />
         <action application="set" data="suppress_cng=true" />
         <action application="answer" />
         <action application="conference" data="$1@cdquality" />
      </condition>
   </extension>
</include>
```

Edit `/opt/freeswitch/etc/freeswitch/autoload_configs/opus.conf.xml` and copy-and-paste the code below, removing the existig code

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration name="opus.conf">
   <settings>
      <param name="use-vbr" value="1" />
      <param name="use-dtx" value="0" />
      <param name="complexity" value="10" />
      <param name="packet-loss-percent" value="15" />
      <param name="keep-fec-enabled" value="1" />
      <param name="use-jb-lookahead" value="1" />
      <param name="advertise-useinbandfec" value="1" />
      <param name="adjust-bitrate" value="1" />
      <param name="maxaveragebitrate" value="256000" />
      <param name="maxplaybackrate" value="48000" />
      <param name="sprop-maxcapturerate" value="48000" />
      <param name="sprop-stereo" value="1" />
      <param name="negotiate-bitrate" value="1" />
   </settings>
</configuration>
```

[Reference](https://groups.google.com/g/bigbluebutton-setup/c/3Y7VBllwpX0/m/41X9j8bvCAAJ)

## Add junc deletion script
Fist nano to:
```
nano /etc/cron.daily/bbb-recording-cleanup
```
Then add these lines:

```sh
cd /var/bigbluebutton
mkdir temp
mv basic_stats configs captions blank deleted diagnostics playback published recording screenshare unpublished events ./temp
mv temp ..
rm -rf *
mv ../temp .
cd temp
mv * ..
cd ..
rm -r temp
```

## Run three parallel Kurento media servers

Available in BigBluebutton 2.2.24 (and later releases of 2.2.x)

Running three parallel Kurento media servers (KMS) – one dedicated to each type of media stream – increases the stability of media handling as the load for starting/stopping media streams spreads over three separate KMS processes. Also, it increases the reliability of media handling as a crash (and automatic restart) by one KMS will not affect the two.

In our experience, we have see CPU usage spread across 3 KMS servers, resulting in better user experience. Hence, we highly recommend it. 

The change required to enable 3 KMS is part of our apply-config-sample.sh included with this project.

## Optimize Recording

### Process multiple recordings

Make changes described in this PR: [Add option to rap-process-worker to accept a filtering pattern](https://github.com/bigbluebutton/bigbluebutton/pull/8394)

```sh
Edit /usr/lib/systemd/system/bbb-rap-process-worker.service and set the command to: ExecStart=/usr/local/bigbluebutton/core/scripts/rap-process-worker.rb -p "[0-4]$"
Copy /usr/lib/systemd/system/bbb-rap-process-worker.service to /usr/lib/systemd/system/bbb-rap-process-worker-2.service
Edit /usr/lib/systemd/system/bbb-rap-process-worker-2.service and set the command to ExecStart=/usr/local/bigbluebutton/core/scripts/rap-process-worker.rb -p "[5-9]$"
Edit /usr/lib/systemd/system/bbb-record-core.target and add bbb-rap-process-worker-2.service to the list of services in Wants
Edit /usr/bin/bbb-record, search for bbb-rap-process-worker.service and add bbb-rap-process-worker-2.service next to it to monitor
```

You will also need to copy the updated version of `rap-process-worker.rb` from [here](https://github.com/daronco/bigbluebutton/blob/9e5c386e6f89303c3f15f4552a8302d2e278d057/record-and-playback/core/scripts/rap-process-worker.rb) to the following location `/usr/local/bigbluebutton/core/scripts`

Ensure the right file permission `chmod +x rap-process-worker.rb`

After making the changes above restart recording process:
```sh
systemctl daemon-reload	
systemctl stop bbb-rap-process-worker.service bbb-record-core.timer	
systemctl start bbb-record-core.timer
```

To verify that the above changes have taken in place, execute the following:
```sh
ps aux | grep rap-process-worker
```

You should see the following two processes:
```sh
/usr/bin/ruby /usr/local/bigbluebutton/core/scripts/rap-process-worker.rb -p [5-9]$
/usr/bin/ruby /usr/local/bigbluebutton/core/scripts/rap-process-worker.rb -p [0-4]$
```
In case you don't see above two processes running, it's likely that you don't have any recording to process. You may want to record a test class using API-MATE and check if the above two processes start running after the end of the test class.

### Import already published recordings from one scalelite to another

To migrate existing, already published recordings, from one Scalelite server to another Scalelite server, follow the steps below:

* make a tar file from the old folder with a path in the form `presentation/<recording-id>/...`
* copy this tar file to `/mnt/scalelite-recordings/var/bigbluebutton/spool/` on the New scalelite server
* After a short while (a few minutes) the recording is automatically imported to the published folder by `scalelite-recording-importer` Docker service

### Troubleshooting

To investigate the processing of a particular recording, you can look at the log files.

The `/var/log/bigbluebutton/bbb-rap-worker` log is a general log file that can be used to find which section of the recording processing is failing. It also logs a message if a recording process is skipped because the moderator did not push the record button.

To investigate an error for a particular recording, check the following log files:
```sh
/var/log/bigbluebutton/archive-<recordingid>.log
/var/log/bigbluebutton/<workflow>/process-<recordingid>.log
/var/log/bigbluebutton/<workflow>/publish-<recordingid>.log
```

#### Check Free Disk Space
One common issue with recording is that your server is running out of free disk space. Here is how to check for disk space usage:

```sh
apt install ncdu
cd /var/bigbluebutton/published/presentation/
# On Scalelite server, check /mnt/scalelite-recordings/var/bigbluebutton/published/presentation for recordings
ncdu
``` 

You should also check disk space used by log files in `/var/log/bigbluebutton` and `/opt/freeswitch/log`. 

## Fix 1007 and 1020 errors

Follow the steps below to resolve 1007/1020 errors that your users may resport in case they are behind a firewall.

#### 1. Update `external.xml` and `vars.xml`
Edit `/opt/freeswitch/conf/sip_profiles/external.xml` and change
```xml
<param name="ext-rtp-ip" value="$${local_ip_v4}"/>
<param name="ext-sip-ip" value="$${local_ip_v4}"/>
```
To 
```xml
<param name="ext-rtp-ip" value="$${external_rtp_ip}"/>
<param name="ext-sip-ip" value="$${external_sip_ip}"/>
```

Edit `/opt/freeswitch/conf/vars.xml`, and change
```xml
<X-PRE-PROCESS cmd="set" data="external_rtp_ip=stun:stun.freeswitch.org"/>
<X-PRE-PROCESS cmd="set" data="external_sip_ip=stun:stun.freeswitch.org"/>
```
To
```xml
<X-PRE-PROCESS cmd="set" data="external_rtp_ip=EXTERNAL_IP_ADDRESS"/>
<X-PRE-PROCESS cmd="set" data="external_sip_ip=EXTERNAL_IP_ADDRESS"/>
```

#### 2. Verify Turn server is accessible 
Verify Turn server is accessible from your BBB serve. If you receive code 0x0001c means STUN is not working. Log into your BBB server and execute the following command: 

```sh
sudo apt install stun-client
stun turn.higheredlab.com
```
Here is another way to test whether a Stun server, we are using Google’s public Stun server, is accessible from your BBB server. Localport could be any available UDP port on your BBB server.

```sh
sudo apt-get install -y stuntman-client$ stunclient --mode full --localport 30000 turn.higheredlab.com 3478
```
Your output should be something like the following:

```sh
Binding test: success
Local address: 95.216.242.244:30000
Mapped address: 95.216.242.244:30000
Behavior test: success
Nat behavior: Direct Mapping
Filtering test: success
Nat filtering: Endpoint Independent Filtering
```

Configure BigBlueButton to use the coturn server by following the instruction [here](https://docs.bigbluebutton.org/2.2/setup-turn-server.html#configure-bigbluebutton-to-use-the-coturn-server)

#### 3. Change in `/etc/turnserver.conf` on the Turn server:
```sh
realm=turn.higheredlab.com
listening-port=3478 #gets error when you setup port 80
tls-listening-port=443
realm=FQDN of Turn server
listening-ip=0.0.0.0
external-ip=Public-IP-of-Turn-server
```

Follow the instructions [here](https://docs.bigbluebutton.org/2.2/setup-turn-server.html) to install Turn server and configure it as mentioned above.

Start turn server by executing `sudo service coturn restart`

#### 4. Set external IP in WebRtcEndpoint.conf.ini 
Edit `/etc/kurento/modules/kurento/WebRtcEndpoint.conf.ini`

Mention external or public IP address of the media server by uncommenting the line below. Doing so has the advantage of not needing to configure STUN/TURN for the media server.
```sh
externalAddress=Public-IP-of-BBB-Server
```

STUN/TURN are needed only when the media server sits behind a NAT and needs to find out its own external IP address. However, if you set a static external IP address as mentioned above, then there is no need for the STUN/TURN auto-discovery. Hence, comment the following: using turn.higheredlab.com (IP address)
```sh
#stunServerAddress=95.217.128.91
#stunServerPort=3478
```

#### 5. Verify your media negotiation timeouts. 
Recommend setting is to set `baseTimeout` to `30000` in `/usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml`


#### 6. Verify Turn is working
Visit `https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/` to check whether your Turn sevrer is working and enter the details below. Change Turn server URL to your Turn server URL.  
```sh
STUN or TURN URI: turn:turn.higheredlab.com:443?transport=tcp
TURN username:
TURN password: xxxx
```

Execute the code below to generate username and password. Replace `f23xxxea3841c9b91e9accccddde850c61` with the `static-auth-secret` from `/etc/turnserver.conf` file on the turn server.

```sh
secret=f23xxxea3841c9b91e9accccddde850c61 && \
time=$(date +%s) && \
expiry=8400 && \
username=$(( $time + $expiry )) &&\
echo username:$username && \
echo password : $(echo -n $username | openssl dgst -binary -sha1 -hmac $secret | openssl base64)
```
Then click `Add Server` and then `Gather candidates` button. If you have done everything correctly, you should see `Done` as the final result. If you do not get any response or if you see any error messages, please double check if you have diligently followed above steps.
### Change processing interval for recordings

Normally, the BigBlueButton server begins processing the data recorded in a session soon after the session finishes. However, you can change the timing for processing by stopping recordings process before beginning of classes and restarting it after ending of classes.

```sh
crontab -e

# Add the following entries
# Stop recording at 7 AM during week days
0 7 * * 1-5 systemctl stop bbb-rap-process-worker.service bbb-record-core.timer
# Start recording at 6 PM during week days; bbb-record-core will automatically launch all workers required for processing
0 18 * * 1-5 systemctl start bbb-record-core.timer
```

### Reboot BBB server

Rebooting BBB server every night would take care of any zombie process or memory leaks. 

So you can set a cron job to reboot the server, say, at mid night. After rebooting BBB starts automatically. When you execute `bbb-conf --check` and `bbb-conf --status` you get correct results. 

However, try to creare and join a meeting, and that doesn't work. You would have to manually start BBB with `bbb-conf --restart` and then everything works as expected.  


## More on BigBlueButton

Check-out the following apps to further extend features of BBB.

### [bbb-twilio](https://github.com/manishkatyan/bbb-twilio)

Integrate Twilio into BigBlueButton so that users can join a meeting with a dial-in number. You can get local numbers for almost all the countries.

### [bbb-mp4](https://github.com/manishkatyan/bbb-mp4)

With this app, you can convert a BigBlueButton recording into MP4 video and upload to S3. You can covert multiple MP4 videos in parallel or automate the conversion process.

### [bbb-streaming](https://github.com/manishkatyan/bbb-streaming)

Livestream your BigBlueButton classes on Youtube or Facebook to thousands of your users.

### [100 Most Googled Questions on BigBlueButton](https://higheredlab.com/bigbluebutton-guide/)

Everything you need to know about BigBlueButton including pricing, comparison with Zoom, Moodle integrations, scaling, and dozens of troubleshooting.


