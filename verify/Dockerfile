FROM 10.21.1.214:5000/gradle
RUN apk --update add curl
WORKDIR /home
ADD verify.sh verify.sh
RUN chmod a+x verify.sh
ENTRYPOINT ["./verify.sh"]