#!/bin/bash
myhostname=`hostname`
APACHE_LOG_DIR=/var/log/apache2
## habilitamos los alias
#sed 's/# alias/ alias/' ~/.bashrc

mkdir -p /run/lock
#2.2.Instalar MySQL/MariaDB.
#aptitude install -y mariadb-client mariadb-server
#Se instal solo el cliente ya que se usara otro contenedor para mariaDB
#aptitude install -y mariadb-client #Se instala desde la imagen

#2.3.Instalar Apache y PHP
aptitude install -y apache2 libapache2-mod-bw unzip zip \
build-essential php php-gd php-phpseclib php-pear php-zip \
php-xml php-readline php-mysql php-mbstring php-json php-gd \
php-curl php-common php-cli php-cgi php-bz2 libapache2-mod-php \
libpq5 php-pgsql php-sqlite3 php-pgsql php-sqlite3 php-imagick \
certbot python3-certbot-apache php-tcpdf

#Iniciamos apache2
/etc/init.d/apache2 start


# Configuracion para instalar Posrtfix desatendido
debconf-set-selections <<< "postfix postfix/mailname string $DNSr" 
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'" 
debconf-set-selections <<< "postfix postfix/destinations string $myhostname, $DNSr, 'localhost.localdomain', 'localhost'"
#NOTA: si pone los valores, pero no lo deja como variable

#debconf-show postfix
#* postfix/main_mailer_type: Internet Site
#  postfix/main_cf_conversion_warning: true
#  postfix/chattr: false
#  postfix/mynetworks: 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
#  postfix/dynamicmaps_conversion_warning:
#* postfix/mailname: trajearteoaxaca.com
#  postfix/retry_upgrade_warning:
#  postfix/relayhost:
#  postfix/mailbox_limit: 0
#  postfix/recipient_delim: +
#  postfix/lmtp_retired_warning: true
#  postfix/relay_restrictions_warning:
#  postfix/root_address:
#  postfix/newaliases: false
#  postfix/rfc1035_violation: false
#  postfix/not_configured:
#  postfix/destinations: $myhostname, trajearteoaxaca.com, ecs-email, localhost.localdomain, localhost
#  postfix/sqlite_warning:
#  postfix/procmail: false
#  postfix/tlsmgr_upgrade_warning:
#  postfix/protocols: all
#  postfix/bad_recipient_delimiter:
#  postfix/mydomain_warning:
#  postfix/compat_conversion_warning: true
#  postfix/kernel_version_warning:



#2.4.Instalar Postfix y Dovecot.
aptitude install -y postfix postfix-mysql \
dovecot-core dovecot-imapd dovecot-lmtpd dovecot-mysql libsasl2-modules \
dovecot-pop3d mysqmail-postfix-logger dovecot-managesieved dovecot-sieve mailutils 

#Revisar los puertos del localhost
#framos@riverside:/bkp1/web$ nmap localhost
#Starting Nmap 7.80 ( https://nmap.org ) at 2021-11-04 11:47 PDT
#Nmap scan report for localhost (127.0.0.1)
#Host is up (0.00012s latency).
#Other addresses for localhost (not scanned): ::1
#Not shown: 990 closed ports
#PORT     STATE SERVICE
#22/tcp   open  ssh
#25/tcp   open  smtp
#80/tcp   open  http
#222/tcp  open  rsh-spx
#443/tcp  open  https
#465/tcp  open  smtps
#587/tcp  open  submission
#993/tcp  open  imaps
#995/tcp  open  pop3s
#8080/tcp open  http-proxy


#Iniciamos dovecot y postfix
/etc/init.d/dovecot start
/etc/init.d/dovecot status

/etc/init.d/postfix start
/etc/init.d/postfix status

# Agregar los registros mx.encoremsi.com
# y el MX apuntando al anterior



#4.1.Configuración del servidor web. 
#Configuración de apache2
cd /etc/apache2/sites-available

#creamos el archivo de configuracion .conf
echo "
<VirtualHost *:80>
    ServerName mx.${DOMAIN}
    # Redirect permanent / https://mx.${DOMAIN}
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    ErrorLog $""{APACHE_LOG_DIR}/error.log
    Customlog $""{APACHE_LOG_DIR}/access.log combined
</VirtualHost>
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName mx.${DOMAIN}
    ServerAlias mx.${DOMAIN}/
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    ErrorLog $""{APACHE_LOG_DIR}/error.log
    Customlog $""{APACHE_LOG_DIR}/access.log combined

SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
</VirtualHost>
</IfModule>" >> mx.$DOMAIN.conf

#habilitamos el sitio
a2ensite mx.$DOMAIN.conf
# para deshabikliatr un sitio: a2dissite

#reiniciamos apache2
/etc/init.d/apache2 restart

#4.2.Creación de los certificados de seguridad SSL/TLS.
certbot --apache
#ponemos mail
#A
#Y
#lejor dominio de l allista
#Luego nos dara 2 opciones,
#1. No redireccionar todo para https
#2. Redireccionar todas las consultas del sitio a través de https.
#elejimos 1 y editamos el archivo
nano -c mx.$DOMAIN.conf
#descomentamos
    #Redirect permanent / https://mx.$DOMAIN

#reiniciamos apache2
/etc/init.d/apache2 restart

## el paso del adminer lo pasamos ya que usarmos un contenedor aparte
#5.2.Configuración de adminer.
    #aptitude install adminer
#Ahora lo compilamos.
    #cd /usr/share/adminer/
    #php compile.php

#Copiaremos este archivo en el mismo directorio con el nombre solo de ​ adminer.php
    #mv adminer.php adminer.php.bkp
    #version=$(ls -lhr | grep adminer- | cut -d " " -f 10)
    #cp $version adminer.php
#cp adminer-4.7.1.php adminer.php


#Ahora creamos un alias en las configuraciones de apache para poder acceder.
    #echo "Alias /adminer.php /usr/share/adminer/adminer.php" | tee /etc/apache2/conf-available/adminer.conf

#Activamos el alias
    #a2enconf adminer.conf

#Reiniciamos el servicio de apache2
#systemctl reload apache2
#y/o --> tambien
#/etc/init.d/apache2 restart


#6.1.Crear usuario del servidor de email.
#es mejor crear diferentes usuarios, por ejemplo uno quesolo pueda leer la base de datos sin poder editar el contenido y otro que pudieraagregar datos pero solo alterar las claves
#mysql -u root -p
#usamos sin -p porque root no tiene password hasta el momento
#mysql -u root

#nos comectamos al contetendo db con user root
mysql -h db -u root -pHuixtepec#295

#Creamos el usuario mailuser:cursoemail
#CREATE USER 'mailuser'@'localhost' IDENTIFIED BY 'cursoemail';

#Meuxubi Alacran
#CREATE USER 'diuxi'@'localhost' IDENTIFIED BY 'Huixtepec295';
#CREATE USER 'diuxi'@'%' IDENTIFIED BY 'Huixtepec295';

#Ahora le daremos todos los privilegios, solo para este curso.
#GRANT ALL PRIVILEGES ON *.* TO 'diuxi'@'localhost' WITH GRANT OPTION;
#flush privileges;
#GRANT ALL PRIVILEGES ON *.* TO 'diuxi'@'%' WITH GRANT OPTION;
#flush privileges;

#Se dio permisos al usuario creado con el Docker-compose
GRANT ALL PRIVILEGES ON *.* TO 'diuxi'@'%' WITH GRANT OPTION;
flush privileges;
#6.2.Crear base de datos y tablas con adminer.
#Base de datos.
#Nombre: mailserver
#Cotejamiento: utf8_general_ci
#mysql -u root
CREATE DATABASE mailserver COLLATE 'utf8_general_ci';

USE mailserver;

CREATE TABLE virtual_aliases (
  id int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  domain_id int(11) NOT NULL,
  source varchar(100) NOT NULL,
  destination varchar(100) NOT NULL
) ENGINE='InnoDB';

CREATE TABLE virtual_domains (
  id int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name varchar(150) NOT NULL
) ENGINE='InnoDB';

CREATE TABLE virtual_users (
  id int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  domain_id int(11) NOT NULL,
  password varchar(106) NOT NULL,
  email varchar(100) NOT NULL,
  quota_rule varchar(10) NOT NULL,
  status_ int(2) NOT NULL DEFAULT '1'
) ENGINE='InnoDB';

#quit

#6.3.Crear cuentas de email, claves, alias y dominios.
#Vamos a generar el hash para la contraseña
#doveadm pw -s SHA512-CRYPT
#Enter new password: Huixtepec
#Retype new password:
##{SHA512-CRYPT}
#$6$nXlK9syMhFxoFWHW$DFJnkPbnq45//aSFJgDx/A7DIS5U/XpWdqm5McF5uswseutIokGKA6K9i9f/f87WHuNTIJuXQVipq6bIaiVe6/

#mysql -u root
#USE mailserver;

INSERT INTO `virtual_domains` (`name`) VALUES ('encoremsi.com');

#Ahora vamos a crear un email: otro@trajearteoaxaca.com
INSERT INTO `virtual_users` (`domain_id`, `password`, `email`, `quota_rule`, `status_`) VALUES ('1', '$6$nXlK9syMhFxoFWHW$DFJnkPbnq45//aSFJgDx/A7DIS5U/XpWdqm5McF5uswseutIokGKA6K9i9f/f87WHuNTIJuXQVipq6bIaiVe6/', 'otro@encoremsi.com', '5M', '1');

#Ahora agregaremos un alias: webmaster@trajearteoaxaca.com ==> otro@trajearteoaxaca.com
INSERT INTO `virtual_aliases` (`domain_id`, `source`, `destination`) VALUES ('1', 'pruebas@encoremsi.com', 'framos11@gmail.com');
quit
#revisar la BD y deben estar las BD mailserver


#7.2.Configuración de Postfix como MTA (Mail Agent Transfer o Agente detransferencia de correo).
#7.2.1.Hacer backup antes de iniciar la configuración.
cp -avr /etc/postfix/ /etc/postfix.bkp

cd /etc/postfix/
#Documentación git Postfix:
#github.com/ibyteman/EmailServer

#7.2.2.Configuración del archivo /etc/postfix/main.cf
nano -c /etc/postfix/main.cf
#Sustituir contenido por el de GIT

#cambiamos los certificados correctos l 23 aprox
# TLS parameters
#smtpd_tls_cert_file=/etc/letsencrypt/live/mx.$DOMAIN/fullchain.pem
#smtpd_tls_key_file=/etc/letsencrypt/live/mx.$DOMAIN/privkey.pem
#smtp_tls_CApath = /etc/letsencrypt/live/mx.$DOMAIN/cert.pem
#smtpd_tls_CApath = /etc/letsencrypt/live/mx.$DOMAIN/cert.pem
#sed -i 's/$DOMAIN/encoremsi.com/g' "/etc/postfix/main.cf"
sed -i 's/byteman.io/becerros.tk/g' "/etc/postfix/main.cf"
#smtpd_use_tls=yes


#cambiamos el DNS del servicor l 87 aprox
#myhostname = 187.250.182.241.dsl.dyn.telnor.net 
#AWS:
#myhostname = ec2-54-153-54-16.us-west-1.compute.amazonaws.com
#HUAWEI>
#myhostname = trajearteoaxaca.com
#Riverside:
#DNSr=cpe-23-242-120-40.socal.res.rr.com
#myhostname = $DNSr
#myhostname = cpe-23-242-120-40.socal.res.rr.com
sed -i 's/ec2-54-150-214-64.ap-northeast-1.compute.amazonaws.com/cpe-23-242-120-40.socal.res.rr.com/g' "/etc/postfix/main.cf"

#7.2.3.Ahora vamos a configurar el archivo ​ master.cf (se usa todo el contenido del GIT)
#nano -c /etc/postfix/master.cf
mv /etc/postfix/master.cf /etc/postfix/master.cf.bkp
#apt-get install wget
wget -P /etc/postfix/ https://raw.githubusercontent.com/framos295/mailserver/byteman/postfix/master.cf


#7.2.4.Ahora vamos a configurar los archivos que postfix necesita para conectarse a la base de datos MariaDB, que ya hemos definido dentro del archivo main.cf.
#nano -c /etc/postfix/mysql-virtual-mailbox-domains.cf
#user = mailuser
#password = cursoemail
#hosts = 127.0.0.1
#dbname = mailserver
#query = SELECT 1 FROM virtual_domains WHERE name='%s'

echo "user = diuxi
password = Huixtepec295
hosts = db
dbname = mailserver
query = SELECT 1 FROM virtual_domains WHERE name='%s'" >> /etc/postfix/mysql-virtual-mailbox-domains.cf


#nano -c /etc/postfix/mysql-virtual-mailbox-maps.cf
#user = mailuser
#password = cursoemail
#hosts = 127.0.0.1
#dbname = mailserver
#query = SELECT 1 FROM virtual_users WHERE email='%s'

echo "user = diuxi
password = Huixtepec295
hosts = db
dbname = mailserver
query = SELECT 1 FROM virtual_users WHERE email='%s'" >> /etc/postfix/mysql-virtual-mailbox-maps.cf

#nano -c /etc/postfix/mysql-virtual-alias-maps.cf
#user = mailuser
#password = cursoemail
#hosts = 127.0.0.1
#dbname = mailserver
#query = SELECT destination FROM virtual_aliases WHERE source='%s'

echo "user = diuxi
password = Huixtepec295
hosts = db
dbname = mailserver
query = SELECT destination FROM virtual_aliases WHERE source='%s'" >>/etc/postfix/mysql-virtual-alias-maps.cf


#nano -c /etc/postfix/mysql-virtual-email2email.cf
#user = mailuser
#password = cursoemail
#hosts = 127.0.0.1
#dbname = mailserver
#query = SELECT email FROM virtual_users WHERE email='%s'

echo "user = diuxi
password = Huixtepec295
hosts = db
dbname = mailserver
query = SELECT email FROM virtual_users WHERE email='%s'" >> /etc/postfix/mysql-virtual-email2email.cf


#Con esto probamos el archivo de acceso a la ​ tabla de dominios. (resoltado=1)
#postmap -q encoremsi.com mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
postmap -q becerros.tk mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
#Ahora la tabla de ​ direcciones de email.  (resoltado=1)
#postmap -q otro@encoremsi.com mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf
postmap -q otro@becerros.tk mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf

#Primero reiniciamos postfix​ , si la respuesta es OK entonces continuamos.
/etc/init.d/postfix restart




#8.-Dovecot como MDA:
#Hacer backup de archivos antes de iniciar la configuración.
cd /etc/dovecot
cp -avr /etc/dovecot/ /etc/dovecot.bkp


#Estructura de directorios de almacenamieto. (para riverside sera en el dico de 1T)
#creamos la carpetas del primer usuario
#mkdir -p /var/mail/vhosts/encoremsi.com
mkdir -p /var/mail/vhosts/becerros.tk

#Creamos el grupo y el usuario para controlar los archivos de email
groupadd -g 5000 vmail
useradd -g vmail -u 5000 vmail -d /var/mail

#Ahora cambiamos el usuario y grupo de todos los directorios donde se almacenarán los emails. Este cambio se hace de forma recursiva, y usaremos el usuario y grupo que acabamos de crear.
    chown -R vmail:vmail /var/mail


#8.2.Configuración de archivos de dovecot. (todo de GIT)
mv /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.bkp
#cp /home/framos/EmailServer-byteman/dovecot/dovecot.conf dovecot.conf
#nano -c /etc/dovecot/dovecot.conf
wget -P /etc/dovecot/ https://raw.githubusercontent.com/framos295/mailserver/byteman/dovecot/dovecot.conf


#todo el contenido de GIT
#cd conf.d/
mv /etc/dovecot/conf.d/10-logging.conf /etc/dovecot/conf.d/10-logging.conf.bkp
#cp /home/framos/EmailServer-byteman/dovecot/10-logging.conf 10-logging.conf
#nano -c /etc/dovecot/conf.d/10-logging.conf
wget -P /etc/dovecot/conf.d https://raw.githubusercontent.com/framos295/mailserver/byteman/dovecot/10-logging.conf


#corregir linea 115 lo correcto de grupo es vmail
mv /etc/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf.bkp
#cp /home/framos/EmailServer-byteman/dovecot/10-mail.conf 10-mail.conf
#nano -c /etc/dovecot/conf.d/10-mail.conf
wget -P /etc/dovecot/conf.d https://raw.githubusercontent.com/framos295/mailserver/byteman/dovecot/10-mail.conf
sed -i 's/mail_privileged_group = mail/mail_privileged_group = vmail/g' "/etc/dovecot/conf.d/10-mail.conf"

#corregir linea 10 = yes
#ilnea 101 se agrega login al final de linea
#linea 122 puede funcionar #!include auth-system.conf.ext o descomentada
#se tiene que descomentar linea 123 !include auth-sql.conf.ext
mv /etc/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf.bkp 
#cp /home/framos/EmailServer-byteman/dovecot/10-auth.conf 10-auth.conf
#nano -c /etc/dovecot/conf.d/10-auth.conf
wget -P /etc/dovecot/conf.d https://raw.githubusercontent.com/framos295/mailserver/byteman/dovecot/10-auth.conf
sed -i 's/disable_plaintext_auth = no/disable_plaintext_auth = yes/g' "/etc/dovecot/conf.d/10-auth.conf"

#el archivo auth-sql-conf-ext esta corecto ya no se configura, en Debian viene ya OK

#lineas importantes 32,75,84,116,140,157
#todo el contenido de GIT con user delcurso, solo corregir la linea 144 falro la s en vhosts
#cd ..
mv /etc/dovecot/dovecot-sql.conf.ext /etc/dovecot/dovecot-sql.conf.ext.bkp 
#cp /home/framos/EmailServer-byteman/dovecot/dovecot-sql.conf.ext dovecot-sql.conf.ext
#nano -c /etc/dovecot/dovecot-sql.conf.ext

wget -P /etc/dovecot/ https://raw.githubusercontent.com/framos295/mailserver/byteman/dovecot/dovecot-sql.conf.ext
# l 75, cambiar la la direccion del hos de bd, user y passwd
sed -i 's/connect = host=127.0.0.1 dbname=mailserver user=mailuser password=cursoemail/#connect = host=127.0.0.1 dbname=mailserver user=mailuser password=cursoemail\nconnect = host=bd dbname=mailserver user=diuxi password=Huixtepec295/g' "/etc/dovecot/dovecot-sql.conf.ext"
# l 140, se corrige vhost por vhosts
sed -i 's/vhost/vhosts/g' "/etc/dovecot/dovecot-sql.conf.ext"


#todo el archivo del repo GIT
#cd conf.d/
mv /etc/dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf.bkp 
#cp /home/framos/EmailServer-byteman/dovecot/10-master.conf 10-master.conf
#nano -c /etc/dovecot/conf.d/10-master.conf
wget -P /etc/dovecot/conf.d/ https://raw.githubusercontent.com/framos295/mailserver/byteman/dovecot/10-master.conf


#se cambia el dominio y comentan lineas 36 y 52
mv /etc/dovecot/conf.d/10-ssl.conf /etc/dovecot/conf.d/10-ssl.conf.bkp 
#cp /home/framos/EmailServer-byteman/dovecot/10-ssl.conf 10-ssl.conf
#nano -c /etc/dovecot/conf.d/10-ssl.conf
wget -P /etc/dovecot/conf.d/ https://raw.githubusercontent.com/framos295/mailserver/byteman/dovecot/10-ssl.conf
# SSL/TLS support: yes, no, required. <doc/wiki/SSL.txt>
#ssl = required
#ssl_cert = </etc/letsencrypt/live/mx.trajearteoaxaca.com/fullchain.pem
#ssl_key = </etc/letsencrypt/live/mx.trajearteoaxaca.com/privkey.pem
sed -i 's/byteman.io/encoremsi.com/g' "/etc/dovecot/conf.d/10-ssl.conf"

#comentar las lineas 52 y 36
# ssl_dh = </usr/share/dovecot/dh.pem
# ssl_client_ca_dir = /etc/ssl/certs
sed -i 's/ssl_dh =/#ssl_dh =/g' "/etc/dovecot/conf.d/10-ssl.conf"
sed -i 's/ssl_client_ca_dir/#ssl_client_ca_dir/g' "/etc/dovecot/conf.d/10-ssl.conf"

#Se usa todo el archivo
mv /etc/dovecot/conf.d/15-mailboxes.conf  /etc/dovecot/conf.d/15-mailboxes.conf.bkp
#cp /home/framos/EmailServer-byteman/dovecot/15-mailboxes.conf 15-mailboxes.conf
#nano -c /etc/dovecot/conf.d/15-mailboxes.conf
wget -P /etc/dovecot/conf.d/ https://raw.githubusercontent.com/framos295/mailserver/byteman/dovecot/15-mailboxes.conf


#Reglas de control y filtrado de correos. Dovecot tiene un complementollamado SIEVE que se encarga de esto, pero hay que configurarlo.

#todo el archivo del repo, checar linea 47
mv /etc/dovecot/conf.d/15-lda.conf /etc/dovecot/conf.d15-lda.conf.bkp 
#cp /home/framos/EmailServer-byteman/dovecot/15-lda.conf 15-lda.conf
#nano -c /etc/dovecot/conf.d/15-lda.conf
wget -P /etc/dovecot/conf.d/ https://raw.githubusercontent.com/framos295/mailserver/byteman/dovecot/15-lda.conf


#Se cambia domino en la linea 26, y puedes cambiar el correo de l webmaster tambien
mv /etc/dovecot/conf.d/20-lmtp.conf /etc/dovecot/conf.d/20-lmtp.conf.bkp
#cp /home/framos/EmailServer-byteman/dovecot/20-lmtp.conf 20-lmtp.conf
##nano -c /etc/dovecot/conf.d/20-lmtp.conf
#postmaster_address = support@trajearteoaxaca.com
wget -P /etc/dovecot/conf.d/ https://raw.githubusercontent.com/framos295/mailserver/byteman/dovecot/20-lmtp.conf

sed -i 's/byteman.io/encoremsi.com/g' "/etc/dovecot/conf.d/20-lmtp.conf"


#todo el archivo de repo (lienes importantes 24,40,41,88)
mv /etc/dovecot/conf.d/90-sieve.conf /etc/dovecot/conf.d/90-sieve.conf.bkp 
#cp /home/framos/EmailServer-byteman/dovecot/90-sieve.conf 90-sieve.conf
#nano -c /etc/dovecot/conf.d/90-sieve.conf
wget -P /etc/dovecot/conf.d/ https://raw.githubusercontent.com/framos295/mailserver/byteman/dovecot/90-sieve.conf


#Ahora creamos el directorio sieve dentro de dovecot.
mkdir -p /etc/dovecot/sieve
#Y creamos la regla que busca un encabezado llamado X-Spam-Level
#nano -c /etc/dovecot/sieve/spamfilter.sieve
#Y pegamos dentro del archivo lo siguiente.
echo 'require ["fileinto"];
# rule:[SPAM]
if header :contains "X-Spam-Level" "*" {
fileinto "Junk";
}' >> /etc/dovecot/sieve/spamfilter.sieve


#Hacemos cambio de de grupo de la carpeta sieve
#cd ..
chown -R root:dovecot /etc/dovecot/sieve/
#Reiniciar dovecot:
/etc/init.d/dovecot restart
#Consultar el estado del servicio:
#systemctl status dovecot.service
###/etc/init.d/dovecot status


#realizar un nmap y ver que desaparece el puerto 143
#nmap localhost
#PORT     STATE SERVICE
#21/tcp   open  ftp
#22/tcp   open  ssh
#25/tcp   open  smtp
#80/tcp   open  http
#443/tcp  open  https
#465/tcp  open  smtps
#587/tcp  open  submission
#993/tcp  open  imaps
#995/tcp  open  pop3s
#3306/tcp open  mysql



### Damos de alta dominio de prueba para test de envio de correos
#https://my.freenom.com/
#   -registro MX
#       -mx.encoremsi.com
#           -Prioridad = 1

# agregamos dominio y correo a la BD
#nos comectamos al contetendo db con user root
mysql -h db -u diuxi -p
    #poner password
USE mailserver;

INSERT INTO `virtual_domains` (`name`) VALUES ('becerros.tk');

#Ahora vamos a crear un email: otro@trajearteoaxaca.com
INSERT INTO `virtual_users` (`domain_id`, `password`, `email`, `quota_rule`, `status_`) VALUES ('2', '$6$nXlK9syMhFxoFWHW$DFJnkPbnq45//aSFJgDx/A7DIS5U/XpWdqm5McF5uswseutIokGKA6K9i9f/f87WHuNTIJuXQVipq6bIaiVe6/', 'admin@becerros.tk', '10M', '1');

quit

#Realizar la prueba de recepcion de correos desde gmail
mail -f /var/mail/vhosts/encoremsi.com/otro
#root@debian:/etc/dovecot# mail -f /var/mail/vhosts/trajearteoaxaca.com/otro
#"/var/mail/vhosts/trajearteoaxaca.com/otro": 1 message 1 new
#>N   1 Fabio Fernando Ram                   59/3084  Prueba 1
#? 

#Eliminar el mensaje pendiente en cola.
postsuper -d <Number>
#Eliminar todos los mensajes pendientes en cola.
postsuper -d ALL
#Encolar de nuevo el mensaje.
postsuper -r <Number>
#Encolar de nuevo todos los mensajes.
postsuper -r ALL
#Mostrar todos los mensajes en cola.
postqueue -p
#Hacer flush de la cola de correo, e intentar enviar o recibir todos nuevamente.
postqueue -f
