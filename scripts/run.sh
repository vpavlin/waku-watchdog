#!/bin/sh

WAKUCANARY=./bin/wakucanary
BRANCH=results

check() {
    local node=$1
    local TIME=$2
    output=$(${WAKUCANARY} -a=${node} -p=relay -p=store)
    success=$([ $? -eq 0 ] && echo 1 || echo 0 )
    ping=$(echo ${output} | grep ping= | sed 's/.*ping=\([0-9]*\).*/\1/')
    relay=$(echo ${output} | grep -q "supported=/vac/waku/relay/2.0.0" && echo 1 || echo 0)
    store=$(echo ${output} | grep -q "supported=/vac/waku/store/2.0.0-beta4" && echo 1 || echo 0)

    #echo ${node} ${TIME} ${success} ${ping}ms ${relay}
    echo '{"node":"'${node}'", "ping": '${ping:-0}', "relay": '${relay}', "store": '${store}', "timestamp": '${TIME}', "success": '${success}'}' 1>&2 #| json_pp

    echo "${node};${TIME};${success};${ping};${relay};${store}"
}

if [ -z ${GITHUB_TOKEN} ]; then
    echo "Failed to find GITHUB_TOKEN"
    sleep 120
fi

git remote set-url origin https://vpavlin:${GITHUB_TOKEN}@github.com/vpavlin/waku-watchdog.git
git checkout ${BRANCH}

p=0
pids=""
while true
do
    curl -O https://raw.githubusercontent.com/vpavlin/waku-watchdog/main/nodes.txt
    TIME=$(date +%s)
    for node in `cat nodes.txt`; do
        check ${node} ${TIME} >> watched.csv &
        pids=${pids}" "$!
        sleep 1
    done

    p=$(( p + 1 ))

    if [ ${p} -eq 5 ]; then
        for pid in `echo $pids`; do
            echo $pid
            wait ${pid}
        done
        pids=""
        echo "Pushing the updates..."
        #git config --global user.name 'Waku Watchdog'
        #git config --global user.email 'vpavlin@users.noreply.github.com'
        git add watched.csv
        git commit -m "watchdog run ${TIME}"
        git pull origin ${BRANCH} --rebase
        git push --set-upstream origin ${BRANCH}
        p=0
    fi

    sleep 1
done
