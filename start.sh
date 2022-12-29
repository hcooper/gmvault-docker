#!/bin/bash
set -euo pipefail

if [ "$GMVAULT_OPTIONS" != "" ]; then
	echo "Gmvault will run with the following additional options: $GMVAULT_OPTIONS."
fi

# Ensure there's an address to send reports to.
export GMVAULT_SEND_REPORTS_TO=${GMVAULT_SEND_REPORTS_TO:="$GMVAULT_EMAIL_ADDRESS"}
echo "Sending email reports to $GMVAULT_SEND_REPORTS_TO."

# Adjust timezone.
GMVAULT_TIMEZONE=${GMVAULT_TIMEZONE:="America/Los_Angeles"}
cp /usr/share/zoneinfo/${GMVAULT_TIMEZONE} /etc/localtime
echo ${GMVAULT_TIMEZONE} >/etc/timezone
echo "Startup: $(date)."

# Set up Gmvault group.
GMVAULT_GID=${GMVAULT_GID:="$GMVAULT_DEFAULT_GID"}
if [ "$(id -g gmvault)" != "$GMVAULT_GID" ]; then
	groupmod -o -g "$GMVAULT_GID" gmvault
fi
echo "Using group ID $(id -g gmvault)."

# Set up Gmvault user.
GMVAULT_UID=${GMVAULT_UID:="$GMVAULT_DEFAULT_UID"}
if [ "$(id -u gmvault)" != "$GMVAULT_UID" ]; then
	usermod -o -u "$GMVAULT_UID" gmvault
fi
echo "Using user ID $(id -u gmvault)."

# Make sure the files are owned by the user executing Gmvault, as we will need
# to add/delete files.
chown -R gmvault:gmvault /data

# Set up crontab.
echo "" >$CRONTAB

emails=($(echo $GMVAULT_EMAIL_ADDRESSES | tr "," "\n"))
for email in "${emails[@]}"; do
	OAUTH_TOKEN="/data/$email.oauth2"

	if [ -f $OAUTH_TOKEN ]; then
		echo "Using OAuth token found at $OAUTH_TOKEN"

		echo "${GMVAULT_FULL_SYNC_SCHEDULE} /app/backup_full.sh $email" >>$CRONTAB
		echo "${GMVAULT_QUICK_SYNC_SCHEDULE} /app/backup_quick.sh $email" >>$CRONTAB

		if [ "$GMVAULT_SYNC_ON_STARTUP" == "yes" ]; then
			if [ -d /data/$email/db ]; then
				echo "Existing database directory found, running quick sync."
				su-exec gmvault /app/backup_quick.sh $email
			else
				echo "No existing database found, running full sync."
				su-exec gmvault /app/backup_full.sh $email
			fi
		else
			echo "No sync on startup, see GMVAULT_SYNC_ON_STARTUP if you would like to change this."
		fi

	else
		echo "#############################"
		echo "#   OAUTH SETUP REQUIRED!   #"
		echo "#############################"
		echo ""
		echo "No Gmail OAuth token found at $OAUTH_TOKEN."
		echo "Please set it up with the instructions at https://github.com/guillaumeaubert/gmvault-docker#running-this-container-for-the-first-time."

		/bin/bash
	fi
done

crond -f
