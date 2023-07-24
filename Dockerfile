FROM 9bkerzya/avari:nox AS qbtbuild
FROM 9bkerzya/avari:base

RUN apt-get update \
    # Needed for qbittorrent-nox runtime.
    && apt-get install -y libqt5network5 libqt5sql5 libqt5xml5 python3 \
    && apt-get clean && rm -rf /var/lib/opt/lists/* /tmp/* /var/tmp/*

RUN apt install -y software-properties-common \
    && add-apt-repository -y ppa:libtorrent.org/1.2-daily \
    && apt update \
    && apt install -y libtorrent-rasterbar2.0 libtorrent-rasterbar10

# Network
RUN apt install -y iproute2 ufw

COPY --from=qbtbuild /usr/bin/qbittorrent-nox /usr/bin

VOLUME /ovpn-files
VOLUME /media
VOLUME /torrents
VOLUME /tmp

RUN mkdir /avari
ADD setup_network.sh /avari/
ADD start.sh /avari/
ADD logging /avari/
ADD qbtorrent /avari/qbtorrent

RUN useradd -ms /usr/sbin/nologin qbtuser
RUN usermod -u 1002 qbtuser
RUN chown -R qbtuser:qbtuser /avari
RUN chmod +x /avari/*.sh /avari/qbtorrent/*.init /avari/qbtorrent/*.sh

ENV TERM=xterm
ENV AVARI_QBT_HOME=/avari/qbtorrent

# Expose WebUI port.
EXPOSE 8080

WORKDIR /avari

CMD ["/bin/bash", "/avari/start.sh"]
