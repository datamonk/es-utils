#!/bin/bash

ES_PS_CHECK=$( netstat -ln | grep "9200" | cut -d" " -f15 )
if [[ ${ES_PS_CHECK} =~ "127.0.0.1:9200" ]]; then
  echo "0 = service ok"
else
  echo "1 = service down"
fi

KB_PS_CHECK=$( netstat -ln | grep "5601" | cut -d" " -f16 )
if [[ ${KB_PS_CHECK} =~ "0.0.0.0:5601" ]]; then
  echo "0 = service ok"
else
  echo "1 = service down"
fi

ES_NODE_CHECK=$( curl --silent -XGET "http://localhost:9200/_cluster/health?pretty" | grep "number_of_nodes" | cut -d" " -f5 | sed 's/,//g' )
if [[ ${ES_NODE_CHECK} =~ "1" ]]; then
  echo "0 = service ok"
else
  echo "1 = service down"
fi
