#!/bin/bash

# shib idp ansible installation script

function usage {
  echo "
usage:	$0 [options] product target
options:	[-v]		( verbose )
		[-d]		( very verbose )
		[-l hostname]	( limit install to 'hostname' )
		[-H]		( list hosts in the cluster )
 
product help:	$0 products

target help:	$0 targets
  "
  exit 1
}

function products {
  echo "
     idp			Installs the entire IdP product
     attribute-resolver		Installs new attribute-resolver.xml and related tools
     relying-party		Installs new relying-party.xml and related tools
     views			Installs new views/*vm
     oidc			Installs new oidc?? (tbd)
     oidc-metadata		Installs new oidc metadata
     cluster			Installs new cluster host list ( e.g. idp01-idp08 )
  "
  exit 1
}

function targets {
  echo "
     eval			Installs to eval host
     prod			Installs to prod hosts 
  "
  exit 1
}

# assure correct user
[[ `id -nu` == 'iamidp' ]] | {
  echo "Run this as user = 'iamidp'"
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

shift $((OPTIND-1))
product="$1"
[[ "$product" == "products" ]] && products
target="$2"
[[ "$target" == "eval" || "$target" == "prod" ]] || usage
[[ -z $playbook ]] && playbook="install-${product}.yml"
echo "Installing $playbook to $target"
[[ -r $playbook ]] || {
  echo "Playbook $playbook not found!"
  exit 1
}

. installer-env/bin/activate

((listhosts>0)) && {
   ansible-playbook ${playbook} --list-hosts -i hosts  --extra-vars "target=${target}"
   exit 0
}

vars=
(( verb>0 )) && vars="$vars -v "
(( debug>0 )) && vars="$vars -vvvv "
[[ -n $limit ]] && {
   [[ $limit == *"."* ]] || limit=${limit}.s.uw.edu
   vars="$vars -l $limit "
}
ansible-playbook ${playbook} $vars -i hosts  --extra-vars "target=${target}"

