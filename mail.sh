#!/usr/bin/env bash

cd "$(dirname "$0")" || exit 1
(
	echo "Subject: furpoll"
	echo 'Content-Type: text/html'
	echo 'From: Asherah Connor <furpoll@asherah.hrzn.ee>'
	echo 'To: Asherah Connor <asherah@hrzn.ee>'
	echo ''
	echo "$@"
) | /usr/sbin/sendmail -t
