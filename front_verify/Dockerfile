FROM alpine:3.2
RUN apk --update add curl
WORKDIR /home
ADD verify.sh verify.sh
RUN chmod a+x verify.sh
ENTRYPOINT ["./verify.sh"]