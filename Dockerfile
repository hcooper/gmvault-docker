FROM alpine:latest

# GMVAULT_DIR allows using a location that is not the default $HOME/.gmvault.
ENV GMVAULT_DIR="/data" \
	GMVAULT_EMAIL_ADDRESS="test@example.com" \
	GMVAULT_FULL_SYNC_SCHEDULE="1 3 * * 0" \
	GMVAULT_QUICK_SYNC_SCHEDULE="1 2 * * 1-6" \
	GMVAULT_DEFAULT_GID="9000" \
	GMVAULT_DEFAULT_UID="9000" \
	CRONTAB="/var/spool/cron/crontabs/gmvault"

VOLUME $GMVAULT_DIR
RUN mkdir /app

# Set up environment.
RUN apk add --update \
	bash \
	ca-certificates \
	mailx \
	py-pip \
	python3 \
	ssmtp \
	shadow \
	su-exec \
	tzdata \
	git

RUN python -m ensurepip && pip install --upgrade pip build

# RUN git clone https://github.com/gaubert/gmvault
RUN git clone https://github.com/hcooper/gmvault-python3 gmvault
RUN sed -i 's/Logbook==0.10.1/Logbook/g' gmvault/setup.py
RUN python3 -m build gmvault
RUN pip install gmvault/dist/gmvault-*.tar.gz

RUN rm -rf /var/cache/apk/*

RUN addgroup -g "$GMVAULT_DEFAULT_GID" gmvault
RUN adduser -H -D -u "$GMVAULT_DEFAULT_UID" -s "/bin/bash" -G "gmvault" gmvault

# Monkey-patch to support large mailboxes.
RUN sed -i '/^import imaplib/a imaplib._MAXLINE = 10000000' $(find / -name 'imapclient.py')

# Copy cron jobs.
COPY backup_quick.sh /app/
COPY backup_full.sh /app/

# Set up entry point.
COPY start.sh /app/
WORKDIR /app
ENTRYPOINT ["/app/start.sh"]
