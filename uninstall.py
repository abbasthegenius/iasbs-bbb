#!/usr/bin/python3
from os import system
import subprocess
a = subprocess.Popen('dpkg -l | grep bbb', shell=True, stdout=subprocess.PIPE).stdout
a = str(a.read())
a = a.split("'")[1]
a = a.split('\\n')
a = a[:-1]
system('cd `grep "presentationDir=" /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties | head -n 1 | cut -d \'=\' -f2` && cd .. && rm -rf bigbluebutton freeswitch kurento meetings streams')
system('rm -rf /etc/bigbluebutton')
system('rm -rf ~/greenlight')

j = []
for i in a:
 i = i.split('  ')
 if i[1]:
  system('apt purge '+i[1]+' -y')

system('apt autoremove -y')
system('apt-get remove  --purge nginx nginx-full nginx-common docker-ce docker-ce-cli -y')
system('apt autoremove -y')
system('rm -f /usr/local/bin/docker-compose')
system('rm -rf /var/www/*')
system('rm -rf /opt/freeswitch')
system('rm -rf /usr/local/bigbluebutton')
system("echo > /etc/resolvconf/resolv.conf.d/head")
system("CD=`tail -n 1 /etc/hosts | cut -d ' ' -f1` && sed -i \"s|$CD| |g\" /etc/hosts")
system("CD=`tail -n 1 /etc/hosts | cut -d ' ' -f4` && sed -i \"s|$CD| |g\" /etc/hosts")
system("sed -i 's|pre-down| |g' /etc/network/interfaces")
system('CD=`tail -n 1 /etc/network/interfaces` && $CD')
system(' echo > /etc/network/interfaces')
input( "enter to reboot: ")
system('reboot')


