ARG BASEIMAGE=alpine:latest
FROM ${BASEIMAGE}

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL mantainer="Fabio Ramos <framos11@gmail.com>" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.name="Samba" \
    org.label-schema.description="Multiarch Samba for amd64 arm32v7 or arm64" \
    org.label-schema.url="https://deft.work/Samba" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/DeftWork/samba" \
    org.label-schema.vendor="Deft Work" \
    org.label-schema.version=$VERSION \
    org.label-schema.schema-version="1.0"


ENV GROUP=encore
ENV GID=1001
ENV USER=framos
ENV PWDUSER=framos11
ENV UID=1000

RUN apk update && apk upgrade && apk add --no-cache bash samba-common-tools samba tzdata && rm -rf /var/cache/apk/*
RUN addgroup -g "$GID" -S "$GROUP"
RUN adduser -u "$UID" -G "$GROUP" "$USER" -SHD
#RUN "$PWDUSER" |tee - |smbpasswd -s -a "$USER"

COPY entrypoint.sh /entrypoint.sh
RUN chmod u+x /entrypoint.sh

EXPOSE 137/udp 138/udp 139 445

HEALTHCHECK --interval=60s --timeout=15s CMD smbclient -L \\localhost -U % -m SMB3

ENTRYPOINT ["/entrypoint.sh"]
