#!/bin/bash

set -o nounset
set -o errexit

function usage() {
    cat <<EOF

    Usage: ${0} sitename [db [samldb]]

    OPTIONS:
      -h        Show usage

EOF
exit
}

while getopts "h" OPTION; do
  case $OPTION in
    h) usage ;;
  esac
done

if [ $# -eq 0 ]; then
  usage
fi

CWD=$PWD
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MAKEFILE=$DIR/"sso.make"
SITENAME=$1
DB=${2:-$SITENAME}
SAMLDB=${3:-$DB}
DRUSH=`which drush`
CURL=`which curl`
GZIP=`which gzip`
TAR=`which tar`
TAIL=`which tail`
SED=`which sed`
CONFIG='simplesamlphp/config/config.php'
HASH=`date | md5`
PASS=`echo $HASH | cut -c 10-20`
SETTINGS='sites/default/settings.php'

mkdir -p $SITENAME
cd $SITENAME
mkdir docroot
cd docroot
$DRUSH make $MAKEFILE -y

# Build settings.php
cp sites/default/default.settings.php $SETTINGS
echo "if (file_exists('/var/www/site-php')) {" >> $SETTINGS
echo "  require '/var/www/site-php/"$SITENAME"/"$DB"-settings.inc';" >> $SETTINGS
echo "}" >> $SETTINGS

ln -s ../simplesamlphp/www simplesaml
cd ..

$CURL -s https://simplesamlphp.org/res/downloads/simplesamlphp-1.11.0.tar.gz | $GZIP -d | $TAR xf -

ln -s simplesamlphp-1.11.0 simplesamlphp

echo -e "" >> $CONFIG

cat $DIR/"configphp.txt" >> $CONFIG

$SED -i "s/mydatabasename/$SAMLDB/g" $CONFIG
$SED -i "s/y0h9d13pki9qdhfm3l5nws4jjn55j6hj/$HASH/g" $CONFIG
$SED -i "s/mysupersecret/$PASS/g" $CONFIG

cd $CWD
