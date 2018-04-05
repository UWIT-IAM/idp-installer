#!/bin/bash

# shib idp ansible installation script

function usage {
  echo "usage: $0 [options] product target "
  echo "       [-v]           ( verbose )"
  echo "       [-d]           ( very verbose )"
  echo "       [-l hostname]  ( limit install to 'hostname' )"
  echo "       [-H]           ( list hosts in the cluster )"
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
while getopts 'h?l:Hvdp:' opt; do
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
    p) playbook=$OPTARG
       ;;
  esac
done

product=idp
eval target="\${$OPTIND}"
[[ -z $target ]] && usage
[[ -z $playbook ]] && playbook="install-${product}.yml"
echo "Installing $playbook to $target"

. installer-env/bin/activate

((listhosts>0)) && {
   ansible-playbook ${playbook} --list-hosts -i hosts  --extra-vars "target=${target}"
   exit 0
}

vars="target=${target} "

vars=
(( verb>0 )) && vars="$vars -v "
(( debug>0 )) && vars="$vars -vvvv "
[[ -n $limit ]] && vars="$vars -l $limit "
ansible-playbook ${playbook} $vars -i hosts  --extra-vars "target=${target}"

