FROM python

#Required for tzdata
ENV TZ=Europe/Amsterdam
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y git unzip curl build-essential cmake ninja-build libx11-dev libxcursor-dev libxi-dev libgl1-mesa-dev libfontconfig1-dev

COPY compile.sh /

VOLUME /dependencies
VOLUME $HOME/Downloads/

WORKDIR $HOME/Downloads/

RUN ["chmod", "+x", "/compile.sh"]

ENTRYPOINT ["/compile.sh"]
