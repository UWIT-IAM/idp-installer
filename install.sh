#!/bin/bash

# shib idp ansible installation script

function usage {
  echo "usage: $0 [options] product target "
  echo "       [-v]           ( verbose )"
  echo "       [-d]           ( very verbose )"
  echo "       [-l hostname]  ( limit install to 'hostname' )"
  echo "       [-H]           ( list hosts in the cluster )"
  echo "       product: idp | gateway | preauth"
  echo "       target: idp_eval | idp_prod"
  exit 1
}

# get the base path
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
base=${dir%/ansible}
cd $dir

playbook=
target=
limit=
verb=0
debug=0
list_hosts=0
gettools=1

# limited args to playbook
OPTIND=1
while getopts 'h?l:Hvd' opt; do
  case "$opt" in
    h) usage
       ;;
    \?) usage
       ;;
    l) limit=$OPTARG
       ;;
    H) listhosts=1
       ;;
    v) verb=1
       ;;
    d) debug=1
       ;;
    q) gettools=0
       ;;
  esac
done

eval product="\${$OPTIND}"
[[ -z $product ]] && usage
(( OPTIND += 1 ))
eval target="\${$OPTIND}"
[[ -z $target ]] && usage
playbook="install-${product}.yml"
echo "Installing $product to $target"

# get ansible-tools
[[ -d ansible-tools ]] || {
   echo "installing ansible-tools tools"
   git clone ssh://git@git.s.uw.edu/iam/ansible-tools.git
} 

export ANSIBLE_LIBRARY=ansible-tools/modules:/usr/share/ansible
. installer-env/bin/activate

((listhosts>0)) && {
   ansible-playbook ${playbook} --list-hosts -i ansible-tools/hosts  --extra-vars "target=${target}"
   exit 0
}

vars="target=${target} "

vars=
(( verb>0 )) && vars="$vars -v "
(( debug>0 )) && vars="$vars -vvvv "
[[ -n $limit ]] && vars="$vars -l $limit "
ansible-playbook ${playbook} $vars -i ansible-tools/hosts  --extra-vars "target=${target}"

