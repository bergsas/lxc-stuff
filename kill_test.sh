#!/bin/bash
for addr in $(sudo lxc-ls -f | awk 'NR==1||/^-/{next} $2~/RUNNING/{print $3}')
do 
  ssh ubuntu@$addr -i ~/.ssh/id_rsa_lxcd -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet "
  (set -x; uname -norip; uptime); 
  if ! pgrep -f ^SCREEN.*$1;
  then
    echo \"NO such test: $1\";
    exit 1;
  fi
  ps -ef | grep -v grep | grep -E SCREEN.*$1; 
  (set -x; pkill -f ^SCREEN.*$1); 
  ps -ef | grep -v grep | grep -E SCREEN.*$1"
done
