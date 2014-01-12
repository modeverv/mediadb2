#! /bin/bash
unicorn -c ./unicorn.conf --env production -D
echo "waiting..."
sleep 5
ps ax|grep unicorn

