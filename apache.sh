#!/bin/bash

apt-get install libapache2-mod-security2;

cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf;

sed -i "s/SecRuleEngine DetectionOnly/SecRuleEngine on/gI" /etc/modsecurity/modsecurity.conf;

iptables -I INPUT -p TCP --dport 22 -m state --state NEW -m recent --set;
iptables -I INPUT -p TCP --dport 22 -m state --state NEW -m recent --update --second 100 --hitcount 3 -j DROP;

rm -rf /usr/share/modsecurity-crs;
git clone https://github.com/spiderlabs/owasp-modsecurity-crs.git /usr/share/modsecurity-crs;

cd /usr/share/modsecurity-crs;
cp crs-setup.conf.example crs-setup.conf;

echo "<IfModule security2_module>
    SecDataDir /var/cache/modsecurity
    IncludeOptional /etc/modsecurity/*.conf
    IncludeOptional /usr/modsecurity-crs/*.conf
    IncludeOptional /usr/modsecurity-crs/rules/*.conf
</IfModule>" > /etc/apache2/mods-enabled/security2.conf

a2enmod headers;

echo "
Header edit set-Cookie ^(.*)\$ \$1;HttpOnly;Secure;
Header always append X-Frame-Options SAMEORIGIN
Header set X-XSS-Protection '1; mode=block'
" >> /etc/apache2/conf-available/security.conf; # Add More rules.

service apache2 restart;
service httpd restart;

a2dismod -f autoindex;
service apache2 restart;

iptables -I INPUT -p TCP --dport 80 -j ACCEPT;
