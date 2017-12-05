FROM debian:stretch

COPY percona-xtrabackup-24_2.4.9-1.stretch_amd64.deb /tmp/percona-xtrabackup.deb
RUN apt-get update && apt-get -y install curl lsb-release \
	libdbd-mysql-perl rsync libaio1 libev4 libnuma1\
	&& dpkg -i /tmp/percona-xtrabackup.deb && rm -Rf /tmp/percona-xtrabackup.deb \
	&& rm -rf /var/lib/apt/lists/*

COPY entrypoint /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint"]
