#!/bin/vbash
# This script goes in /config/scripts/post-config.d

# Variables you'll need to change are in parameter.env
source /config/scripts/post-config.d/parameter.env

#################################################################################
### Don't change anything beyond this point unless you know what you're doing ###
#################################################################################

# Include some of the vyatta commands we'll need
source /opt/vyatta/etc/functions/script-template
run=/opt/vyatta/bin/vyatta-op-cmd-wrapper

# Init the temp files
touch /tmp/temp.vpnpeer
touch /tmp/temp.vpnpeer2

# Grab the list of vpn login trial without success of VPN connections
# Limit to 1000 line to ensure not flood /tmp filesystem
# Remove /var/log/messages?? in order to avoid change when log rotate occurs :) and notif again
# Filter only today trial to avoid notification several day later. Prefer notif sooner. 
# Note: There is a short time window of a trials of login 1 min before 00:00 where it will not be
# reported. The risk is very small as not lot of user/log cannot be tested during this time frame.
# FIXME: A notification will occurs when log will disapear. This is better than not being notified
today_filter="$(date | cut -d " " -f2-4)"
grep Peer /var/log/messages* | head -n 1000 | cut -d':' -f2- | grep "$($today_filter)"> /tmp/temp.vpnpeer

# Check if they differ from the last time we checked
if ! cmp -s /tmp/temp.vpnpeer /tmp/temp.vpnpeer2
then
    #Filter empty file (no more connection found) and so avoid false notif (mitigate above FIXME).
    if [ -s /tmp/temp.vpnpeer ];
    then

    echo "WARNING: VPN Activity detected!  Sending e-mail..."

    # Someone try to connect without success
    connInfo="$(</tmp/temp.vpnpeer)"

    echo "Subject: WARNING VPN activity login without success detected on $ClientsName's network!

VPN connection trial without sucess was detected on your network:

$connInfo

    " > /tmp/temp.vpnpeeremail

    /usr/sbin/ssmtp "$DestinationEmail" < /tmp/temp.vpnpeeremail

    echo "Done!"

    fi
    # Back up this run so we can compare later
    cp /tmp/temp.vpnpeer /tmp/temp.vpnpeer2
fi

