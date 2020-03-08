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
touch /tmp/temp.vpnconnections
touch /tmp/temp.vpnconnections2

touch /tmp/temp.vpnfulllist
touch /tmp/temp.vpnfulllist2

# Grab the full list of VPN connections
$run show vpn remote-access > /tmp/temp.vpnfulllist

# Parse out just the user and ip address
cat /tmp/temp.vpnfulllist|grep $IPSegment|awk -F' ' '{printf "%s %s\n", $1, $5}' > /tmp/temp.vpnconnections

# Check if they differ from the last time we checked
if ! cmp -s /tmp/temp.vpnconnections /tmp/temp.vpnconnections2
then
    echo "VPN Activity detected!  Sending e-mail..."

    # Someone connected to/disconnected from the VPN!  Send an e-mail notification
    connInfo="$(</tmp/temp.vpnfulllist)"
    connInfo2="$(</tmp/temp.vpnfulllist2)"

    echo "Subject: VPN activity detected on $ClientsName's network!

    VPN connection activity was detected on your network:
    ---- Current active connection ----

    $connInfo

    ---- Previous status 1 min ago ----

    $connInfo2

    " > /tmp/temp.vpnemail

    /usr/sbin/ssmtp $DestinationEmail < /tmp/temp.vpnemail

    echo "Done!"

    # Back up this run so we can compare later
    cp /tmp/temp.vpnconnections /tmp/temp.vpnconnections2
fi
# Back up this run to use it later for stat
cp /tmp/temp.vpnfulllist /tmp/temp.vpnfulllist2

# Call bad login
source /config/scripts/post-config.d/search-login-trial.sh

