#!/bin/bash

#
# Som alltid: alt for komplisert.
#   Men: moro med kompliserte script.
#

main()
{
  # http://www.zdnet.com/ubuntu-lxd-not-a-docker-replacement-a-docker-enhancement-7000035463/
  # http://www.ubuntu.com/cloud/tools/lxd

  # Only add repo if not already there
  [ ! -e /etc/apt/sources.list.d/cloudarchive-juno.list ] &&
    sudo add-apt-repository cloud-archive:juno

  # Update/upgrade only if it has been more than three hours since last update
  if [ "$(find /var/lib/apt/periodic/update-success-stamp -mmin +$((60*3)))" ]
  then
    sudo apt-get update 
    sudo apt-get -y upgrade
  fi

  # Install this/these packages only if not existing.
  for pkg in nova-compute-flex iperf sysstat 
  do
    dpkg-query -W $pkg >/dev/null 2>&1 ||
      sudo apt-get -qq -y install $pkg
  done


  # Create id_rsa_lxcd and id_rsa_lxcd.pub only if they don't exist

  genkey_for_user root
  genkey_for_user vagrant

  # https://www.stgraber.org/2013/12/20/lxc-1-0-your-first-ubuntu-container/

  n=0
  M=10  # Create M lxc instances
  while [ $n -lt $M ]
  do 
    let n++
    pn=p$n
 
    # If instance exists check that it is running
    # If instance doesn't exist, create it.
    sudo lxc-info -sn $pn >/dev/null 2>&1 ||
      sudo lxc-create -t ubuntu -n $pn
 
    # If instance is STOPPED, start it:
    sudo lxc-info -sn $pn 2>/dev/null | grep -qn STOPPED &&
      sudo lxc-start -n $pn -d

    # Ugh. For convenience. :)
    distribute_pubkey_to_pn_user vagrant $pn ubuntu    
    distribute_pubkey_to_pn_user vagrant $pn root
    distribute_pubkey_to_pn_user root $pn ubuntu
    distribute_pubkey_to_pn_user root $pn root
    
    # Do something here, perhaps?
    # Install iperf :)
    for pkg in iperf screen
    do
      sudo lxc-attach -n "$pn" -- bash -c "dpkg-query -W $pkg >/dev/null 2>&1 || apt-get -y -qq install $pkg"
    done
  done

  # Output list of instances
  sudo lxc-ls -f

  # watch -n0.1 "set -x; dd conv=fsync if=/dev/zero of=/tmp/blurp bs=1M count=1k; dd conv=fsync if=/tmp/blurp of=/tmp/myfile bs=1M; done"

}

genkey_for_user()
{
  eval local rsa_key=~$1/.ssh/id_rsa_lxcd
  local pubkey=$rsa_key.pub
  [ ! -e $rsa_key ] && [ ! -e $pubkey ] && sudo -u $1 ssh-keygen -t rsa -f $rsa_key -N ''
}

# Distribute keys. Me no like hacks. :)
distribute_pubkey_to_pn_user()
{
  # $1 = pubkey user
  # $2 = pn
  # $3 = pn user
  eval local pubkey=~$1/.ssh/id_rsa_lxcd.pub
  eval local authkeys=~$3/.ssh/authorized_keys
  sudo lxc-attach -n $2 -- bash -c "
    [ -d ~$3/.ssh/ ] || mkdir ~$3/.ssh/; 
    grep -q \"$(cat "$pubkey")\" $authkeys 2>/dev/null || 
      echo \"$(cat "$pubkey")\" >> $authkeys "
}

main
