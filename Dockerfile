FROM ubuntu:18.04

VOLUME /ovpn-files
VOLUME /media
VOLUME /torrents

RUN apt-get update \
    # Need software-properties-common for add-apt-repository
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:qbittorrent-team/qbittorrent-stable \
    && apt-get update \
    && apt-get install -y qbittorrent-nox openvpn \
    && apt-get install -y net-tools iptables moreutils ipcalc kmod \
    && apt-get install -y curl vim \
    && apt-get clean && rm -rf /var/lib/opt/lists/* /tmp/* /var/tmp/*

RUN curl -s -L https://github.com/Sylvain303/docopts/releases/download/v0.6.3-alpha1/docopts -o /usr/local/bin/docopts
RUN chmod +x /usr/local/bin/docopts

RUN mkdir /avari
ADD start.sh /avari/
ADD logging /avari/
ADD openvpn /avari/openvpn
ADD qbtorrent /avari/qbtorrent
RUN mkdir /avari/qbtorrent/config

RUN useradd -ms /usr/sbin/nologin qbtuser
RUN usermod -u 1002 qbtuser
RUN chown -R qbtuser:qbtuser /avari
RUN chmod +x /avari/*.sh /avari/openvpn/*.sh /avari/qbtorrent/*.init /avari/qbtorrent/*.sh

ENV TERM=xterm
ENV AVARI_HOME=/avari
ENV AVARI_OPVN_HOME=/avari/openvpn
ENV AVARI_QBT_HOME=/avari/qbtorrent
# ENV LAN_NETWORK=
# ENV PUID=
# ENV PGID=

# Expose ports Web Admin and torrent port
EXPOSE 8080
EXPOSE 49571
EXPOSE 49571/udp

WORKDIR /avari

CMD ["/bin/bash", "/avari/start.sh"]
