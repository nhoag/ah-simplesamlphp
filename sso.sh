#!/bin/bash

set -o nounset
set -o errexit

CWD=$PWD
DRUSH=`which drush`
MAKEFILE=$PWD/$1
SITENAME=$2
DB=${3:-$SITENAME}
SAMLDB=${4:-$DB}
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

$CURL -s https://gist.githubusercontent.com/acquialibrary/8059715/raw/8ceedefe20225c21bc45905bbfedd47143b333b6/9191_configphp.txt \
  | $TAIL -n +2 >> $CONFIG

$SED -i "s/mydatabasename/$SAMLDB/g" $CONFIG
$SED -i "s/y0h9d13pki9qdhfm3l5nws4jjn55j6hj/$HASH/g" $CONFIG
$SED -i "s/mysupersecret/$PASS/g" $CONFIG

cd $CWD
