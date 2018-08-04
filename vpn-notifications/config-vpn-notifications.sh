#!/bin/vbash
# This script goes in /config/scripts/post-config.d

# Variables you'll need to change
HostName='myroutershostname.somedomain.local'  # Hostname of your USG
RouterUser='admin'  # Default username for your USG
MailServer='smtp.gmail.com'  # SMTP Server
MailPort='587'  # SMTP Server Port
EmailAddress='example.user@gmail.com'  # E-mail address to send as
AuthUser='example.user'  # SMTP Username
Password='SomeP@ssword12345'  # SMTP Password


#################################################################################
### Don't change anything beyond this point unless you know what you're doing ###
#################################################################################

# Include some of the vyatta commands we'll need
source /opt/vyatta/etc/functions/script-template
readonly logFile="/var/log/config-smtp.log"

# Write aliases config
cat > /etc/ssmtp/revaliases <<EOF
# sSMTP aliases
# 
# Format:	local_account:outgoing_address:mailhub
#
# Example: root:your_login@your.domain:mailhub.your.domain[:port]
# where [:port] is an optional port number that defaults to 25.
root:$EmailAddress:$MailServer:$MailPort
$RouterUser:$EmailAddress:$MailServer:$MailPort
www-data:$EmailAddress:$MailServer:$MailPort
EOF

# Write SMTP config
cat > /etc/ssmtp/ssmtp.conf <<EOF
#
# Config file for sSMTP sendmail
#
# The person who gets all mail for userids < 1000
# Make this empty to disable rewriting.
root=$EmailAddress

# The place where the mail goes. The actual machine name is required no 
# MX records are consulted. Commonly mailhosts are named mail.domain.com
mailhub=$MailServer:$MailPort

AuthUser=$AuthUser
AuthPass=$Password
UseSTARTTLS=YES

# Where will the mail seem to come from?
rewriteDomain=

# The full hostname
hostname=$HostName

# Are users allowed to set their own From: address?
# YES - Allow the user to specify their own From: address
# NO - Use the system generated From: address
FromLineOverride=YES
EOF

# Add a scheduled task to send the e-mails every minute
configure
set system task-scheduler task check-vpn-connections executable path "/config/scripts/post-config.d/notify-on-vpn-state-change.sh"
set system task-scheduler task check-vpn-connections interval "1m"
commit
save
exit
