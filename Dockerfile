FROM ubuntu

RUN apt-get update && apt-get install -y curl unzip git gcc g++ gcc-multilib g++-multilib lib32stdc++-4.8-dev lib32z1 lib32z1-dev libc6-dev-i386 libc6-i386

USER root

WORKDIR /root

RUN curl -sqL https://mms.alliedmods.net/mmsdrop/1.10/mmsource-1.10.7-git957-linux.tar.gz | tar zxvf -

RUN curl -sqL https://sm.alliedmods.net/smdrop/1.8/sourcemod-1.8.0-git5992-linux.tar.gz | tar zxvf -

WORKDIR /root/addons/sourcemod

RUN while [ ! -f system2.zip ]; do curl -sqL "https://forums.alliedmods.net/attachment.php?attachmentid=106692&d=1494760788" -o system2.zip; done; \
    unzip system2.zip && \
    rm system2.zip

RUN curl -sqL https://github.com/thraaawn/SMJansson/archive/master.zip -o smjansson.zip && \
    unzip smjansson.zip && \
    cp -r SMJansson-master/pawn/scripting/* /root/addons/sourcemod/scripting/ && \
    cp SMJansson-master/bin/smjansson.ext.so /root/addons/sourcemod/extensions/ && \
    chmod +x /root/addons/sourcemod/extensions/smjansson.ext.so && \
    rm -Rf SMJansson-master smjansson.zip

WORKDIR /root

RUN curl -sqL http://users.alliedmods.net/~kyles/builds/SteamWorks/SteamWorks-git121-linux.tar.gz | tar zxvf -

VOLUME /root/plugin

VOLUME /root/compiled

ADD compile.sh /root

ENTRYPOINT ["./compile.sh"]
