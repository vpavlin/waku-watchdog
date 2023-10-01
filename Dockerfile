FROM fedora

WORKDIR /opt/

RUN dnf -y install git

RUN  git config --global user.name 'Waku Watchdog' &&\
     git config --global user.email 'vpavlin@users.noreply.github.com'

RUN date > /opt/date &&\
    git clone https://github.com/vpavlin/waku-watchdog.git

WORKDIR /opt/waku-watchdog

ENTRYPOINT [ /opt/waku-watchdog/scripts/run.sh ]