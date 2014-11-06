#!/bin/bash

# I need a better way. :)

for addr in $(sudo lxc-ls -f | awk 'NR==1||/^-/{next} $2~/RUNNING/{print $3}')
do 
  ssh ubuntu@$addr -i ~/.ssh/id_rsa_lxcd -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet "set -x; 
    if pgrep -f ^SCREEN.*DD_TEST; 
      then echo 'DD_TEST already running (see pid above)';
      exit 1; 
    fi; 
    screen -dmS DD_TEST bash -c 'watch -n0.1 \"set -x; dd conv=fsync if=/dev/zero of=/tmp/blurp bs=1M count=1k; dd conv=fsync if=/tmp/blurp of=/tmp/myfile bs=1M; done\"'"
done
