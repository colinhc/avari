FROM 9bkerzya/avari:nox-latest AS qbtbuild
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

WORKDIR /avari
COPY setup_network.sh .
COPY start.sh .
COPY logging .
COPY qbtorrent/ ./qbtorrent/

RUN MONTH=$(date +%Y-%m) \
    && curl -L https://download.db-ip.com/free/dbip-country-lite-$MONTH.mmdb.gz \
        -o ./dbip-country-lite.mmdb.gz \
    && gzip -d /avari/dbip-country-lite.mmdb.gz \
    && mkdir -p /avari/qbtorrent/qBittorrent/data/GeoDB \
    && mv /avari/dbip-country-lite.mmdb /avari/qbtorrent/qBittorrent/data/GeoDB

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
