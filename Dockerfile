FROM fedora

WORKDIR /opt/waku-watchdog

RUN dnf -y install git

RUN  git config --global user.name 'Waku Watchdog' &&\
     git config --global user.email 'vpavlin@users.noreply.github.com'

RUN git clone https://github.com/vpavlin/waku-watchdog.git

ENTRYPOINT [ /opt/waku-watchdog/scripts/run.sh ]