#!/usr/bin/python3
from os import system
import subprocess
a = subprocess.Popen('dpkg -l | grep bbb', shell=True, stdout=subprocess.PIPE).stdout
a = str(a.read())
a = a.split("'")[1]
a = a.split('\\n')
a = a[:-1]
system('rm -rf /etc/bigbluebutton')
j = []
for i in a:
 i = i.split('  ')
 if i[1]:
  system('apt purge '+i[1]+' -y')

system('apt autoremove -y')
system('apt-get remove  --purge nginx nginx-full nginx-common -y')
system('apt autoremove -y')
system('rm -rf /var/www/*')
system('rm -rf /opt/freeswitch')
system('rm -rf /usr/local/bigbluebutton')
input( "enter to reboot: ")
system('reboot')