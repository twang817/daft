FROM alpine:3.7

RUN apk add --no-cache \
        openssh \
        openssh-server-pam \
        socat \
        tini \
        gnupg \
    && mkdir /root/.ssh /mnt/gpg \
    && chmod 700 /root/.ssh /mnt/gpg

COPY sshd_config /etc/ssh/
COPY docker-entrypoint.sh /
COPY ssh-entrypoint.sh /

EXPOSE 22

ENTRYPOINT ["/sbin/tini", "--", "/docker-entrypoint.sh"]

CMD ["/usr/sbin/sshd", "-D"]
