#!/bin/sh

WAKUCANARY=./bin/wakucanary
BRANCH=results
SLEEP=${WATCHDOG_SLEEP:-1}
UPLOAD_AFTER=${WATCHDOG_UPLOAD_AFTER:-5}

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
git pull origin ${BRANCH}

mkdir -p nodes

p=0
pids=""

curl -o nodes/nodes.txt -L https://raw.githubusercontent.com/vpavlin/waku-watchdog/main/nodes.txt 2> /dev/null
echo "==> Starting the canary loop..."
while true
do
    TIME=$(date +%s)
    SUFFIX=$(( ${TIME} - (${TIME} % 3600) ))
    RESULTS=watched-${SUFFIX}.csv
    for node in `cat nodes/nodes.txt`; do
        check ${node} ${TIME} >> ${RESULTS} &
        pids=${pids}" "$!
        sleep 1
    done

    p=$(( p + 1 ))

    if [ ${p} -eq ${UPLOAD_AFTER} ]; then
        echo "==> Waiting for canaries to finish"
        for pid in `echo $pids`; do
            wait ${pid}
        done
        pids=""
        echo "==> Pushing the updates..."
        git add ${RESULTS}
        git commit -m "watchdog run ${TIME}"
        git pull --rebase #origin ${BRANCH}
        git push #--set-upstream origin ${BRANCH}
        p=0
        curl -o nodes/nodes.txt -L https://raw.githubusercontent.com/vpavlin/waku-watchdog/main/nodes.txt 2> /dev/null
    fi

    sleep ${SLEEP}
done
