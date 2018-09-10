#/bin/sh

if [ "$(id -u)" != "0"  ]; then
  echo "Don't forget to sudo!" 1>&2
  exit 1
fi

if [ -z "$1" ]; then
  echo "Missing argument, please provide sitearchive as \$1"
  exit
fi

if [ -z "$2" ]; then
  echo "Missing argument, please provide site to rebuild as \$2"
  echo "Available options are: ['default', 'ilsecolo', 'openaccess', 'all']"
  exit
fi

if [ "$2" != "default" ] && [ "$2" != "ilsecolo" ] && [ "$2" != "openaccess" ] && [ "$2" != "all" ]; then
  echo "Error: bad target \"$2\" provided, this is not an available option"
  echo "Available options are: ['default', 'ilsecolo', 'openaccess', 'all']"
  exit
fi

SITEARCHIVE=`basename $1`
TMPDIR=/tmp/drupal-rebuild
CURDIR=`pwd`

echo
echo  "Refreshing $TMPDIR..."
rm -rf $TMPDIR
mkdir $TMPDIR

echo "Copying $1 to $TMPDIR..."
cp $1 $TMPDIR

echo "Unpacking $SITEARCHIVE..."
cd $TMPDIR; tar -xzf "$TMPDIR/$SITEARCHIVE"

echo "Preserving site-specific assets (.htaccess, settings.php)..."
cp /var/www/html/.htaccess "$TMPDIR/.htaccess"
cp /var/www/html/sites/default/settings.php "$TMPDIR/default.settings.php"
cp /var/www/html/sites/ilsecolo.lib.fsu.edu/settings.php "$TMPDIR/ilsecolo.settings.php"
cp /var/www/html/sites/openaccess.fsu.edu/settings.php "$TMPDIR/openaccess.settings.php"

echo "Resetting filesystem..."
NEWROOT="$TMPDIR/home/backrest/restore/${SITEARCHIVE%%.*}/drupal"
rm -rf /var/www/html
cp -rf $NEWROOT /var/www/
mv /var/www/drupal /var/www/html
cp "$TMPDIR/.htaccess" /var/www/html/.htaccess
cp "$TMPDIR/default.settings.php" /var/www/html/sites/default/settings.php
cp "$TMPDIR/ilsecolo.settings.php" /var/www/html/sites/ilsecolo.lib.fsu.edu/settings.php
cp "$TMPDIR/openaccess.settings.php" /var/www/html/sites/openaccess.fsu.edu/settings.php
chown -R backrest:apache /var/www/html
find /var/www/html/sites/default/files -type d -exec chmod 775 {} \;
find /var/www/html/sites/ilsecolo.lib.fsu.edu/files -type d -exec chmod 775 {} \;
find /var/www/html/sites/openaccess.fsu.edu/files -type d -exec chmod 775 {} \;

if [ "$2" == "default" ] || [ "$2" == "all" ]; then
  echo "Resetting default database..."
  DEFAULTDATABASE=`cat /tmp/drupal-rebuild/default.settings.php | grep "      'database'" | cut -d "'" -f 4`
  DEFAULTHOST=`cat /tmp/drupal-rebuild/default.settings.php | grep "      'host' => 'beta-db" | cut -d "'" -f 4`
  DEFAULTUSERNAME=`cat /tmp/drupal-rebuild/default.settings.php | grep "      'username'" | cut -d "'" -f 4`
  DEFAULTPASSWORD=`cat /tmp/drupal-rebuild/default.settings.php | grep "      'password'" | cut -d "'" -f 4`
  DEFAULTPREFIX=`cat /tmp/drupal-rebuild/default.settings.php | grep "      'prefix'" | cut -d "'" -f 4`
  DEFAULTNEWSQL="$TMPDIR/home/backrest/restore/${SITEARCHIVE%%.*}/default.sql"
  echo "Connecting to $DEFAULTHOST ..."
  mysql -h $DEFAULTHOST -u $DEFAULTUSERNAME --password=$DEFAULTPASSWORD $DEFAULTDATABASE < $DEFAULTNEWSQL
fi

if [ "$2" == "ilsecolo" ] || [ "$2" == "all" ]; then
  echo "Resetting ilsecolo database..."
  ILSECOLODATABASE=`cat /tmp/drupal-rebuild/ilsecolo.settings.php | grep "      'database'" | cut -d "'" -f 4`
  ILSECOLOHOST=`cat /tmp/drupal-rebuild/ilsecolo.settings.php | grep "      'host' => 'beta-db" | cut -d "'" -f 4`
  ILSECOLOUSERNAME=`cat /tmp/drupal-rebuild/ilsecolo.settings.php | grep "      'username'" | cut -d "'" -f 4`
  ILSECOLOPASSWORD=`cat /tmp/drupal-rebuild/ilsecolo.settings.php | grep "      'password'" | cut -d "'" -f 4`
  ILSECOLOPREFIX=`cat /tmp/drupal-rebuild/ilsecolo.settings.php | grep "      'prefix'" | cut -d "'" -f 4`
  ILSECOLONEWSQL="$TMPDIR/home/backrest/restore/${SITEARCHIVE%%.*}/ilsecolo.sql"
  echo "Connecting to $ILSECOLOHOST ..."
  mysql -h $ILSECOLOHOST -u $ILSECOLOUSERNAME --password=$ILSECOLOPASSWORD $ILSECOLODATABASE < $ILSECOLONEWSQL
fi

if [ "$2" == "openaccess" ] || [ "$2" == "all" ]; then
  echo "Resetting openaccess database..."
  OPENACCESSDATABASE=`cat /tmp/drupal-rebuild/openaccess.settings.php | grep "      'database'" | cut -d "'" -f 4`
  OPENACCESSHOST=`cat /tmp/drupal-rebuild/openaccess.settings.php | grep "      'host' => 'beta-db" | cut -d "'" -f 4`
  OPENACCESSUSERNAME=`cat /tmp/drupal-rebuild/openaccess.settings.php | grep "      'username'" | cut -d "'" -f 4`
  OPENACCESSPASSWORD=`cat /tmp/drupal-rebuild/openaccess.settings.php | grep "      'password'" | cut -d "'" -f 4`
  OPENACCESSPREFIX=`cat /tmp/drupal-rebuild/openaccess.settings.php | grep "      'prefix'" | cut -d "'" -f 4`
  OPENACCESSNEWSQL="$TMPDIR/home/backrest/restore/${SITEARCHIVE%%.*}/oa.sql"
  echo "Connecting to $OPENACCESSHOST ..."
  mysql -h $OPENACCESSHOST -u $OPENACCESSUSERNAME --password=$OPENACCESSPASSWORD $OPENACCESSDATABASE < $OPENACCESSNEWSQL
fi

echo "Drupal rebuild complete!"
cd $CURDIR
