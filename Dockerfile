FROM debian:jessie

# Set timezone to Asia/Shanghai
RUN set -e \
        && echo "Asia/Shanghai" > /etc/timezone \
        && dpkg-reconfigure -f noninteractive tzdata

RUN mkdir /docker-entrypoint-initdb.d /docker-entrypoint-updatedb.d

# Debian mirror in China
RUN { \
		echo "deb http://ftp.cn.debian.org/debian/ jessie main"; \
		echo "deb http://ftp.cn.debian.org/debian/ jessie-updates main"; \
	} > /etc/apt/sources.list

ENV MYSQL_VERSION 5.5

RUN set -e \
	&& { \
		echo mysql-server-${MYSQL_VERSION} mysql-server/root_password password 'pass'; \
		echo mysql-server-${MYSQL_VERSION} mysql-server/root_password_again password 'pass'; \
	} | debconf-set-selections \
	&& apt-get update && apt-get install -y netcat mysql-server-${MYSQL_VERSION} && rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mysql/*

# comment out a few problematic configuration values
# don't reverse lookup hostnames, they are usually another container
RUN set -e \
	&& sed -Ei 's/^bind-address/#&/' /etc/mysql/my.cnf \
	&& { \
		echo "[mysqld]"; \
		echo "skip-name-resolve"; \
		echo "skip-host-cache"; \
		echo "datadir = /var/lib/mysql"; \
	} > /etc/mysql/conf.d/docker.cnf

VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

# mysqld serves at 3306, while an echo server serves at 13306 (see docker-entrypoint.sh)
EXPOSE 3306 13306
CMD ["mysqld"]
