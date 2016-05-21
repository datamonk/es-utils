#!/bin/bash

DATE=$( date +%Y%m%d )
INPUT_FILE="input-file.csv"
JSON_FILE="json-output.bulk"
ES_URL="http://localhost:9200"
ES_INDEX="baseline-${DATE}"
ES_MAPPER="baseline"

if [[ ! -f "${INPUT_FILE}" ]]; then echo "no input file" && exit 0; fi
if [[ -f "${JSON_FILE}" ]]; then rm -f ${JSON_FILE}; touch ${JSON_FILE}; fi

elastic_validator() {
## check if index already exists
curl -XDELETE "${ES_URL}/${ES_INDEX}"
elastic_loader
}

elastic_loader() {
## bulk load output file to es api
curl -XPOST "${ES_URL}/${ES_INDEX}" --data-binary '{
    "mappings" : {
      "'${ES_MAPPER}'" : {
        "properties" : {
          "enclave" : {
            "type" : "string"
          },
          "subnet" : {
            "type" : "string"
          },
          "ipAddress" : {
            "type" : "string"
          },
          "rcdType" : {
            "type" : "string"
          },
          "rcdAttr" : {
            "type" : "string"
          }
        }
      }
    }
}'

# Load json data
curl -XPOST "${ES_URL}/${ES_INDEX}/_bulk" --data-binary "@${JSON_FILE}"
sleep 5
curl -XGET "${ES_URL}/_cat/indices?v"
}

json_builder() {
echo -e '{"index" : {"_type" : "'${ES_MAPPER}'", "_id" : "1"}}' >> ${JSON_FILE}
COUNT="1"
while read line; do
  LINE=$line
  ENCLAVE=$( echo ${LINE} | cut -d "," -f1  )
  SUBNET=$( echo ${LINE} | cut -d "," -f2  )
  IP_ADDR=$( echo ${LINE} | cut -d "," -f3  )
  RECORD_TYPE=$( echo ${LINE} | cut -d "," -f4  )
  RECORD_ATTR=$( echo ${LINE} | cut -d "," -f5  )
    if [[ "${COUNT}" -lt "2" ]]; then
      let COUNT=${COUNT}+1
    else
      echo -e '{"create" : {"_type" : "'${ES_MAPPER}'", "_id" : "'$(echo ${COUNT})'"}}' >> ${JSON_FILE}
      let COUNT=${COUNT}+1
    fi
  echo -e '{"enclave": "'${ENCLAVE}'", "subnet": "'${SUBNET}'", "ipAddress": "'${IP_ADDR}'", "rcdType": "'${RECORD_TYPE}'", "rcdAttr": "'${RECORD_ATTR}'"}' >> ${JSON_FILE}
done < ${INPUT_FILE}

elastic_validator
}

if [[ -f "${INPUT_FILE}" ]]; then json_builder; fi
