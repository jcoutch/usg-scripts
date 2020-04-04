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

# Grab the list of vpn login trial without success  of VPN connections
# Limit to 1000 line to ensure not flood  /tmp filesystem
grep Peer /var/log/messages* | head -n 1000 > /tmp/temp.vpnpeer

# Check if they differ from the last time we checked
if ! cmp -s /tmp/temp.vpnpeer /tmp/temp.vpnpeer2
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

    # Back up this run so we can compare later
    cp /tmp/temp.vpnpeer /tmp/temp.vpnpeer2
fi
