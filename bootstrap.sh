#!/usr/bin/env bash

##Based on this https://www.dev-metal.com/super-simple-vagrant-lamp-stack-bootstrap-installable-one-command/ provisioning script
##but with locale setting and nvm

# Use single quotes instead of double quotes to make it work with special-character passwords
PASSWORD=$2
PROJECTFOLDER=$1

#set the locale, which causes issues with the package manager if not set
sudo locale-gen en_GB.UTF-8

# create project folder
sudo mkdir -p "${PROJECTFOLDER}"

# update / upgrade
sudo apt-get update

# install mysql and give password to installer
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get -y install mysql-server

# install apache 2.5 and php 7
sudo apt-get install -y apache2
sudo apt-get install -y php libapache2-mod-php php-mcrypt php-mysql php-xml php-mbstring php-curl

#install zip and unzip for composer
sudo apt-get -y install zip unzip

# install git
sudo apt-get -y install git

# install composer


# setup hosts file
sudo cat <<EOF | sudo tee /etc/apache2/sites-available/$PROJECTFOLDER.conf
<VirtualHost *:80>
    DocumentRoot /var/www/vhosts/${PROJECTFOLDER}/public
    <Directory /var/www/vhosts/${PROJECTFOLDER}/public>
        AllowOverride all
        Require all granted
    </Directory>
</VirtualHost>
EOF

# replace AllowOverride to All so htaccess works
sudo sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf



#remove apache default index
sudo rm -rf /var/www/html

# enable mod_rewrite
sudo a2enmod rewrite

# enable the site
sudo a2ensite $PROJECTFOLDER.conf
sudo a2dissite 000-default.conf

# install nvm
sudo curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.1/install.sh | bash

sudo curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
cd /var/www/vhosts/${PROJECTFOLDER} && composer install

# restart apache
sudo service apache2 restart

echo 'Done.'
