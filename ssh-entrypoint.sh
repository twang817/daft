#!/bin/sh

FORWARDED_SOCKET=/mnt/ssh/ssh-agent.sock

[ -z "$SSH_AUTH_SOCK" ] && exit 1

rm -f $FORWARDED_SOCKET
socat UNIX-LISTEN:$FORWARDED_SOCKET,fork,mode=777 UNIX-CONNECT:$SSH_AUTH_SOCK
