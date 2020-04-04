### WARNING: While I've made every effort to ensure these scripts work properly on my test device, use of these scripts are at your own risk. I will not be held liable for any damages caused directly/indirectly by their usage.

# VPN e-mail notifications

The set of scripts in this directory will poll the USG's VPN connection list every minute and report any VPN connectivity changes.

# Installation
- Create a file parameter.env with the following content
```
# This script goes in /config/scripts/post-config.d

# Variables you'll need to change config-vpn-notifications.sh
HostName='myroutershostname.somedomain.local'  # Hostname of your USG
RouterUser='admin'  # Default username for your USG
MailServer='smtp.gmail.com'  # SMTP Server
MailPort='587'  # SMTP Server Port
EmailAddress='example.user@gmail.com'  # E-mail address to send as
AuthUser='example.user'  # SMTP Username
Password='SomeP@ssword12345'  # SMTP Password


# Variables you'll need to change for notify-on-vpn-state-change.sh
IPSegment='10.0'  # The IP address segment your VPN is located on (i.e. '10.0.' or '192.168.1.')
DestinationEmail='user@example.com'  # Where to send e-mails to
ClientsName='StringToDifferenciatNetworks'
```

- To start the scripts two options:

- Option1: Prefered which remain active when new provision occurs: In CloudKey
- Push the scripts to your USG via `scp`, replacing the username and ip address with your own:
```
scp parameter.env admin@192.168.0.1:/config/scripts/post-config.d/
scp config-vpn-notifications.sh admin@192.168.0.1:/config/scripts/post-config.d/
scp notify-on-vpn-state-change.sh admin@192.168.0.1:/config/scripts/post-config.d/
```

Follow to find where the gateway.json is in your CloudKey https://help.ubnt.com/hc/en-us/articles/215458888-UniFi-How-to-further-customize-USG-configuration-with-config-gateway-json 
with the following content added to your gateway.json
```{
	"system": {
		"task-scheduler": {
			"task": {
				"check-vpn-connections": {
					"executable": {
						"path": "/config/scripts/post-config.d/notify-on-vpn-state-change.sh"
					},
				"interval": "1m"
				}
			}
		}
	}
}
```
Log into USG and render scripts executable.

Option 2: By "hand"
- Push the scripts to your USG via `scp`, replacing the username and ip address with your own:
```
scp parameter.env admin@192.168.0.1:/config/scripts/post-config.d/
scp config-vpn-notifications.sh admin@192.168.0.1:/config/scripts/post-config.d/
scp notify-on-vpn-state-change.sh admin@192.168.0.1:/config/scripts/post-config.d/
scp config-vpn-notifications.sh admin@192.168.0.1:/config/scripts/post-config.d/
```
Then you'll need to log in via SSH, change the scripts to executable, and execute `config-vpn-notifications.sh` for the first time via `sudo`.  After that, the script will be set up as a scheduled task, and will persist after reboots.  On upgrades, both scripts will be executed once the upgrade is complete, re-establishing the scheduled task:
```
cd /config/scripts/post-config.d
chmod a+x config-vpn-notifications.sh
chmod a+x notify-on-vpn-state-change.sh
sudo ./config-vpn-notifications.sh
```

# Removal For option 2
- Connect to the USG via SSH, and run the following commands:
```
configure
delete system task-scheduler task check-vpn-connections
commit
save
exit
cd /config/scripts/post-config.d
rm config-vpn-notifications.sh
rm notify-on-vpn-state-change.sh
```

That will remove the scheduled task, and remove the scripts from the USG.


# Example E-mail Output

When users connect:

```
Received: by myroutershostname.somedomain.local (sSMTP sendmail emulation); Sat, 04 Aug 2018 19:10:02 -0400
From: root <example.user@gmail.com>
Date: Sat, 04 Aug 2018 19:10:02 -0400
Subject: VPN activity detected

    VPN connection activity was detected on your network:

    Active remote access VPN sessions:
     ---- Current active connection ----

User       Time      Proto Iface   Remote IP       TX pkt/byte   RX pkt/byte  
---------- --------- ----- -----   --------------- ------ ------ ------ ------
some.user  00h00m12s L2TP  l2tp0   10.0.0.1           56  11.6K     70   8.3K

Total sessions: 1

    ---- Previous status 1 min ago ----

    No active remote access VPN sessions
```

When the last user has disconnected:
```
Received: by myroutershostname.somedomain.local (sSMTP sendmail emulation); Sat, 04 Aug 2018 19:12:01 -0400
From: root <example.user@gmail.com>
Date: Sat, 04 Aug 2018 19:12:01 -0400
Subject: VPN activity detected

    VPN connection activity was detected on your network:

     ---- Current active connection ----

    No active remote access VPN sessions

    ---- Previous status 1 min ago ----

User       Time      Proto Iface   Remote IP       TX pkt/byte   RX pkt/byte  
---------- --------- ----- -----   --------------- ------ ------ ------ ------
some.user  01h00m12s L2TP  l2tp0   10.0.0.1          156  11.6G     90   8.3M

```
