FROM martinhelmich/xtrabackup
COPY entrypoint /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint && \
	apt-get update && apt-get -y install \
	 curl \
	&& rm -rf /var/lib/apt/lists/*
ENTRYPOINT ["/usr/local/bin/entrypoint"]
