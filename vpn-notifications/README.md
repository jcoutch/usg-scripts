### WARNING: While I've made every effort to ensure these scripts work properly on my test device, use of these scripts are at your own risk. I will not be held liable for any damages caused directly/indirectly by their usage.

# VPN e-mail notifications

The set of scripts in this directory will poll the USG's VPN connection list every minute and report any VPN connectivity changes.

# Installation
- Modify the settings at the top of both `config-vpn-notifications.sh` and `notify-on-vpn-state-change.sh`
- Push the scripts to your USG via `scp`, replacing the username and ip address with your own:
```
scp config-vpn-notifications.sh admin@192.168.0.1:/config/scripts/post-config.d/
scp notify-on-vpn-state-change.sh admin@192.168.0.1:/config/scripts/post-config.d/
```
- To start the scripts, you'll need to log in via SSH, change the scripts to executable, and execute `config-vpn-notifications.sh` for the first time via `sudo`.  After that, the script will be set up as a scheduled task, and will persist after reboots.  On upgrades, both scripts will be executed once the upgrade is complete, re-establishing the scheduled task:
```
cd /config/scripts/post-config.d
chmod a+x config-vpn-notifications.sh
chmod a+x notify-on-vpn-state-change.sh
sudo ./config-vpn-notifications.sh
exit
```

# Removal
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

User       Time      Proto Iface   Remote IP       TX pkt/byte   RX pkt/byte  
---------- --------- ----- -----   --------------- ------ ------ ------ ------
some.user  00h00m12s L2TP  l2tp0   10.0.0.1           56  11.6K     70   8.3K

Total sessions: 1
```

When the last user has disconnected:
```
Received: by myroutershostname.somedomain.local (sSMTP sendmail emulation); Sat, 04 Aug 2018 19:10:02 -0400
From: root <example.user@gmail.com>
Date: Sat, 04 Aug 2018 19:12:01 -0400
Subject: VPN activity detected

    VPN connection activity was detected on your network:

    No active remote access VPN sessions
```
