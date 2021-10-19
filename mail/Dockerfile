## Archivo de creacion de Imagen Debian 11
FROM debian
RUN apt-get update
RUN apt-get  install -y iputils-ping \
    aptitude htop vim nmap nano iproute2 \
    net-tools openssh-server lsb-release

RUN aptitude update

## INSTALACION DE MariaDB ##
RUN aptitude install -y mariadb-client mariadb-server

#2.3.Instalar Apache y PHP y NMAP para análisis de puertos.
RUN aptitude install -y apache2 libapache2-mod-bw unzip zip \
    build-essential php php-gd php-phpseclib php-pear php-zip \
    php-xml php-readline php-mysql php-mbstring php-json php-gd \
    php-curl php-common php-cli php-cgi php-bz2 libapache2-mod-php \
    libpq5 php-pgsql php-sqlite3 php-pgsql php-sqlite3 php-imagick \
    certbot python-certbot-apache php-tcpdf 

## EXPOSE PUERTOS ##
EXPOSE 22/tcp
EXPOSE 25/tcp
EXPOSE 80/tcp
EXPOSE 443/tcp
EXPOSE 465/tcp
EXPOSE 587/tcp
EXPOSE 993/tcp
EXPOSE 995/tcp
EXPOSE 3306/tcp

## VOLUMES ##
VOLUME ["/prueba/postgresql", "/prueba1/log/postgresql", "/prueba1/lib/postgresql"]

CMD ["/bin/bash"]
