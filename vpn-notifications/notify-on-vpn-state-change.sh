#!/bin/vbash
# This script goes in /config/scripts/post-config.d

# Variables you'll need to change
IPSegment='10.0.'  # The IP address segment your VPN is located on (i.e. '10.0.' or '192.168.1.')
DestinationEmail='user@example.com'  # Where to send e-mails to


#################################################################################
### Don't change anything beyond this point unless you know what you're doing ###
#################################################################################

# Include some of the vyatta commands we'll need
source /opt/vyatta/etc/functions/script-template
run=/opt/vyatta/bin/vyatta-op-cmd-wrapper

# Init the temp files
touch /tmp/temp.vpnconnections
touch /tmp/temp.vpnconnections2

# Grab the full list of VPN connections
$run show vpn remote-access > /tmp/temp.vpnfulllist

# Parse out just the user and ip address
cat /tmp/temp.vpnfulllist|grep $IPSegment|awk -F' ' '{printf "%s %s\n", $1, $5}' > /tmp/temp.vpnconnections

# Check if they differ from the last time we checked
if ! cmp -s /tmp/temp.vpnconnections /tmp/temp.vpnconnections2
then
    echo "VPN Activity detected!  Sending e-mail..."

    # Someone connected to/disconnected from the VPN!  Send an e-mail notification
    connInfo=$(</tmp/temp.vpnfulllist)

    echo "Subject: VPN activity detected

    VPN connection activity was detected on your network:

    $connInfo
    " > /tmp/temp.vpnemail

    /usr/sbin/ssmtp $DestinationEmail < /tmp/temp.vpnemail

    echo "Done!"

    # Back up this run so we can compare later
    cp /tmp/temp.vpnconnections /tmp/temp.vpnconnections2
fi