# setup for iam ansible install
# all as root

# bail on any error
set -e

# who is this
user="`ls -ld $SSH_TTY|awk '{print $3}'`"
echo "run by: $user"

# sanity check for proper system
case `id -nu` in
 fox)
          ;;
 root)
          ;;
 *) echo "This script must run as root"
    exit 1
    ;;
esac
[[ -d /etc/daemons && -d /usr/local/apache && -d /usr/local/ssl ]] || {
  echo "This doesn't look like a proper iam host."
  exit 1
}

x="`echo ~iamidp`"
[[ $x == '~iamidp' ]] && {
  echo "User 'iamidp' must be present"
  exit 2
}

(( verbose=1 ))

iamown="iamidp"
iamgrp="iam-dev"
services=" $* "

# setup something with iamidp.iam-grp owner

# test file/dir properties
# $1=file/dir $2=mode $3=owner $4=group
# return "" if ok
function okfd {
  m="`stat -c '%a' $1`"
  [[ $m = $2 ]] || echo "mode"
  o="`stat -c '%U' $1`"
  [[ $o = $3 ]] || echo "owner"
  g="`stat -c '%G' $1`"
  [[ $g = $4 ]] || echo "group"
}

# arg is existing file
function iamfile {
  fil=$1
  m=644
  [[ "$2" != "" ]] && m=$2
  (( verbose)) && echo "file: $fil"
  [[ -f $fil ]] || {
     echo "not a regular file: $fil"
     exit 1
  }
  [[ "$(okfd $fil $m $iamown $iamgrp)" == "" ]] || {
    chown ${iamown}.${iamgrp} $fil
    chmod $m $fil
  }
}

# arg is directory 
function iamdir {
  dir=$1
  m=755
  [[ "$2" != "" ]] && m=$2
  (( verbose)) && echo "dir:  $dir"
  [[ -d $dir ]] || {
    echo "making $dir"
    mkdir $dir
  }
  [[ "$(okfd $dir $m $iamown $iamgrp)" == "" ]] || {
    chown ${iamown}.${iamgrp} $dir
    chmod $m $dir
  }
}

echo "iamidp home"
iamdir ~iamidp/.ssh
[[ -f ~iamidp/.ssh/authorized_keys ]] || {
   cat << END > ~iamidp/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAvn95T9vKkldb11f+B80RTOsTvsR9oysP0dXFiK5aVGVDLZ+KaqahqBAaJVeGYrb6IzU9qHUemCJNvPi/xGTqb3oe6F8l6niRCGpaopHjFoGhQaLbGRr0JYjH/S83ktUFocPmGcqdFhTd7vkhp2mlyO1H1BsOkeY/4Yrw5Dr4Wm4EUETyquJncrB85X/1G+fzS3XxxN/Jh4/Fhq8wqiZv0T4ZbzP/1PGUA1N+9vx//BYgzLVySlhhLa8dMZNEoM7bgRpgK4XBrv5vpDhzoCvEGOCu9jIfZ5Yb4ogVowDIHnHwLuQCNprTHZgwON49B63oLAoCO8hMhk+7LFjlq/ynKw== fox@x315.cac.washington.edu
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEArkcnfaEmqFyrfQRQKVtXjtqcdoDmJ4dfvuDqOamLqd2D3viYEkjr/qTLzEhPujFTmL8x+QU2F9S9LtWEsUbtlVaxd9PT9Sebx8okAXbtSuolxP33oO/tXJ/BBTJo2GrI0fVhfPqu9rJvtpKsxazbWcZboTIL0OGdUIm3f11lyE8ksGHJI7Y9EygSN/3YsloFiKR6xpsfo97k1iV6D/s5sItXPUEWT5XSr4GBLW3LgE0yiRJbLQ/vLk+l1/py0xVJeeWNsMngVxJXHLtmh3vfFJJZ9kxSPR8pwen/fV/yfFDankFb42VT6lOU1g3xb/RSlb/bS11Z3vyhV4jTlVVDnQ== fox@idpdev01.s.uw.edu
END
}


echo "data local and ansible-comand"
[[ -d /data/local ]] || mkdir /data/local
[[ -d /data/local/src ]] || mkdir /data/local/src
[[ -d /data/local/bin ]] || mkdir /data/local/bin
[[ -x /data/local/bin/ansible_command ]] || {
  ((verbose)) && echo "ansible-command"
  cd /data/local/src
  wget https://iam-tools.u.washington.edu/iam-ansible/host-tools.tar.gz
  tar xf host-tools.tar.gz
  rm host-tools.tar.gz
  cd host-tools
  make install
}

echo "cluster commands"
[[ -x /data/local/bin/add_to_cluster ]] || {
cat << END > /data/local/bin/add_to_cluster
echo "server-status: Enabled
status-by: add_to_cluster command, user=`whoami`" > /www/host_status.txt
END
}
[[ -x /data/local/bin/remove_from_cluster ]] || {
cat << END > /data/local/bin/remove_from_cluster
echo "server-status: Disabled
status-by: remove_from_cluster command, user=`whoami`" > /www/host_status.txt
END
}


cd /data/local

iamdir /data/local/etc

echo "apache"
function confd {
  [[ -f /data/conf/apache-${1} && "`cat /data/conf/apache-${1}`" = "Include /data/conf/apache.conf.d/${1}.*" ]] || {
    echo "Include /data/conf/apache.conf.d/${1}.*" > /data/conf/apache-${1}
  }
}
iamdir /data/conf/apache.conf.d/
confd global
confd http
confd https


# web sites
iamdir /data/www/
iamdir /data/tomcatsettings
iamdir /data/webapps
iamdir /www/js
iamdir /www/css
iamdir /www/img
iamdir /www/public
iamdir /www/gc

iamdir /data/local/idp-3.2

iamdir /logs/idp

# prime the apache configs
[[ -f /data/conf/apache.conf.d/global.0base ]] || {
  wget -O /data/conf/apache.conf.d/global.0base http://idp01.s.uw.edu/public/global.0base.txt
}
[[ -f /data/conf/apache.conf.d/http.0base ]] || {
  wget -O /data/conf/apache.conf.d/http.0base http://idp01.s.uw.edu/public/http.0base.txt
}
[[ -f /data/conf/apache.conf.d/https.0base ]] || {
  wget -O /data/conf/apache.conf.d/https.0base http://idp01.s.uw.edu/public/https.0base.txt
}

# setup tomcat java args
cat > /etc/daemons/tomcat << END
-server -XX:+UseParallelGC -Xss24m -Xms4g -Xmx4g -XX:MaxGCPauseMillis=400 -Dlog4j.configuration=file:/usr/local/tomcat/conf/log4j.properties -XX:+PrintGC -XX:+PrintGCDateStamps -Xloggc:/www/gc/idp.gc -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=20 -XX:GCLogFileSize=1M -Didp.home=/data/local/idp-3.3
END

# see if there is a local idp database
# else get frm idp01
echo "check tgtid database"
set +e
/usr/local/pgversion/bin/psql -U postgres -c '\d' idp > /dev/null 2>&1
ret=$?
(( ret==0 )) || {
  echo "creating postgres database: idp"
  echo "use password for $USER (twice)"
  {
   eval cd ~${USER}
   ssh -l $USER idp01 '/usr/local/pgversion/bin/pg_dump -U postgres -C idp > idp.sql'
   scp ${USER}@idp01:idp.sql /tmp/idp.sql
   /usr/local/pgversion/bin/psql -U postgres -c "create user shib with encrypted password '1234'"
   /usr/local/pgversion/bin/psql -U postgres -c "create user shibadmin with encrypted password '1234'"
   /usr/local/pgversion/bin/psql -U postgres < /tmp/idp.sql
   rm /tmp/idp.sql
  }
}

