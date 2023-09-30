FROM fedora

WORKDIR /opt/waku-watchdog

RUN git clone https://github.com/vpavlin/waku-watchdog.git

ENTRYPOINT [ /opt/waku-watchdog/scripts/run.sh ]