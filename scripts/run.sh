#!/bin/sh

WAKUCANARY=./bin/wakucanary

TIME=$(date +%s)
for node in `cat nodes.txt`; do
    output=$(${WAKUCANARY} -a=${node} -p=relay)
    success=$([ $? -eq 0 ] && echo true || echo false )
    ping=$(echo ${output} | grep ping= | sed 's/.*ping=\([0-9]*\).*/\1/')
    relay=$(echo ${output} | grep -q supported=/vac/waku/relay/2.0.0 && echo true || echo false)
    #echo ${node} ${TIME} ${success} ${ping}ms ${relay}
    echo "${node};${TIME};${success};${ping};${relay};" >> watched.csv
    echo '{"node":"'${node}'", "ping": '${ping:-0}', "relay": '${relay}', "timestamp": '${TIME}', "success": '${success}'}' #| json_pp
done

git config --global user.name 'Waku Watchdog'
git config --global user.email 'vpavlin@users.noreply.github.com'
git add watched.csv
git commit -m "watchdog run ${TIME}"
git push
