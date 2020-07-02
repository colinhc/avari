FROM 9bkerzya/avari:nox AS qbtbuild
FROM 9bkerzya/avari:base

RUN apt-get update \
    && apt-get install -y openvpn \
    && apt-get clean && rm -rf /var/lib/opt/lists/* /tmp/* /var/tmp/*

COPY --from=qbtbuild /usr/bin/qbittorrent-nox /usr/bin

VOLUME /ovpn-files
VOLUME /media
VOLUME /torrents

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
