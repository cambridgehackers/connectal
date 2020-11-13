FROM bsc-contrib:latest
ADD . /build/
RUN apt update; apt-get -y install jq python python-ply rsync awscli
ENV PATH /opt/bluespec/bin:$PATH
ENV BLUESPECDIR /opt/bluespec/lib
