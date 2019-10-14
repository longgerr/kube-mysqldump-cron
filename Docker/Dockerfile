FROM alpine:3.4
RUN apk add --update mysql-client bash openssh-client && rm -rf /var/cache/apk/*
COPY dump.sh /
RUN chmod +x /dump.sh
COPY import.sh /
RUN chmod +x /import.sh
ENTRYPOINT ["/dump.sh"]
