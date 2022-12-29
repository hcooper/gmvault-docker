#!/bin/bash
set -euo pipefail

email=$1

echo "Starting quick sync of $email."
echo "Report will be sent to $GMVAULT_SEND_REPORTS_TO."

gmvault sync -t quick -d /data/$email $GMVAULT_OPTIONS $email 2>&1 |
	tee /data/${email}/${email}_quick.log |
	mail -s "Mail Backup (quick) | $email | $(date +'%Y-%m-%d %r %Z')" $GMVAULT_SEND_REPORTS_TO

echo "Quick sync complete."
