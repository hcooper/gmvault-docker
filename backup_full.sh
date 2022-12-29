#!/bin/bash
set -euo pipefail

email=$1

echo "Starting full sync of $email."
echo "Report will be sent to $GMVAULT_SEND_REPORTS_TO."

gmvault sync -d /data/$email $GMVAULT_OPTIONS $email 2>&1 |
	tee /data/${email}/${email}_full.log |
	mail -s "Mail Backup (full) | $email | $(date +'%Y-%m-%d %r %Z')" $GMVAULT_SEND_REPORTS_TO

echo "Full sync complete."
