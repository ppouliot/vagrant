#!/bin/bash
# Author: Jon Schipp <jonschipp@gmail.com>
# Written for Ubuntu Saucy and Trusty, should be adaptable to other distros.

## Variables
HOME=/root
cd $HOME

# Installation notification
COWSAY=/usr/games/cowsay
IRCSAY=/usr/local/bin/ircsay
IRC_CHAN="#replace_me"
HOST=$(hostname -s)
LOGFILE=/root/islet_install.log
EMAIL=user@company.com

function die {
  if [ -f ${COWSAY:-none} ]; then
    $COWSAY -d "$*"
  else
    echo "$*"
  fi
  if [ -f $IRCSAY ]; then
    ( set +e; $IRCSAY "$IRC_CHAN" "$*" 2>/dev/null || true )
  fi
  echo "$*" | mail -s "[vagrant] Bro Sandbox install information on $HOST" $EMAIL
  exit 1
}

function hi {
  if [ -f ${COWSAY:-none} ]; then
    $COWSAY "$*"
  else
    echo "$*"
  fi
  if [ -f $IRCSAY ]; then
    ( set +e; $IRCSAY "$IRC_CHAN" "$*" 2>/dev/null || true )
  fi
  echo "$*" | mail -s "[vagrant] Bro Sandbox install information on $HOST" $EMAIL
}

install_dependencies(){
  apt-get update -qq
  apt-get install -yq cowsay git make sqlite pv
}

install_islet(){
  if ! [ -d islet ]
  then
    git clone http://github.com/jonschipp/islet || die "Clone of islet repo failed"
    cd islet
    make install-docker && make docker-config && ./configure && make logo &&
    make user-config && make install && make security-config && make iptables-config || die "ISLET install failed\!"
    #make install-brolive-config
    #make install-sample-distros
    make install-sample-nsm-configs
  fi
}

install_dependencies "1.)"
install_islet "2.)"

echo -e "\nTry it out: ssh -p 2222 demo@127.0.0.1 -o UserKnownHostsFile=/dev/null"
