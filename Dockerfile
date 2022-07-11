FROM 9bkerzya/avari:nox AS qbtbuild
FROM 9bkerzya/avari:base

RUN apt-get update \
    # Needed for qbittorrent-nox runtime.
    && apt-get install -y qt5-qmake libqt5network5 libqt5sql5 libqt5xml5 \
    && apt-get install -y openvpn \
    && apt-get clean && rm -rf /var/lib/opt/lists/* /tmp/* /var/tmp/*

RUN apt install -y software-properties-common \
    && add-apt-repository -y ppa:libtorrent.org/1.2-daily \
    && apt update \
    && apt install -y libtorrent-rasterbar10

COPY --from=qbtbuild /usr/bin/qbittorrent-nox /usr/bin

VOLUME /ovpn-files
VOLUME /media
VOLUME /torrents
VOLUME /tmp

RUN mkdir /avari
ADD start.sh /avari/
ADD logging /avari/
ADD openvpn /avari/openvpn
ADD qbtorrent /avari/qbtorrent

RUN useradd -ms /usr/sbin/nologin qbtuser
RUN usermod -u 1002 qbtuser
RUN chown -R qbtuser:qbtuser /avari
RUN chmod +x /avari/*.sh /avari/openvpn/*.sh /avari/qbtorrent/*.init /avari/qbtorrent/*.sh

ENV TERM=xterm
ENV AVARI_HOME=/avari
ENV AVARI_OPVN_HOME=/avari/openvpn
ENV AVARI_QBT_HOME=/avari/qbtorrent

# Expose ports Web Admin and torrent port
EXPOSE 8080
EXPOSE 49571
EXPOSE 49571/udp

WORKDIR /avari

CMD ["/bin/bash", "/avari/start.sh"]
