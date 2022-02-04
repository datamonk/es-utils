#!/bin/bash

# Record date
DATE=$( date +%Y%m%d )
# Path of input file (CSV formatted)
INPUT_FILE="input-file.csv"
# Path of output file (JSONish formatted)
JSON_FILE="json-output.bulk"
# Elasticsearch Instance API URL
ES_URL="http://localhost:9200"
# Desired ES index name
ES_INDEX="baseline-${DATE}"
# Desired ES mapping/schema name
ES_MAPPER="baseline"

# Exit if $INPUT_FILE doesn't exist
if [[ ! -f "${INPUT_FILE}" ]]; then /bin/echo "no input file" && exit 0; fi
# Remove $JSON_FILE if exists from past execution
if [[ -f "${JSON_FILE}" ]]; then /bin/rm -f ${JSON_FILE}; /usr/bin/touch ${JSON_FILE}; fi

index_cleanup() {
## Delete existing index if it exists
/usr/bin/curl -XDELETE "${ES_URL}/${ES_INDEX}"

# Move on to es loader for data ingest
bulk_loader
}

bulk_loader() {
## Load index mapping, update if present already
/usr/bin/curl -XPOST "${ES_URL}/${ES_INDEX}" --data-binary '{
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

## Create new index and load $JSON_FILE using bulk endpoint
/usr/bin/curl -XPOST "${ES_URL}/${ES_INDEX}/_bulk" --data-binary "@${JSON_FILE}"
/bin/sleep 5
## Query index listing to confirm new index
/usr/bin/curl -XGET "${ES_URL}/_cat/indices?v"
}

json_builder() {
# Add header to json file to identify index
/bin/echo -e '{"index" : {"_type" : "'${ES_MAPPER}'", "_id" : "1"}}' >> ${JSON_FILE}
# Start recording count to structure meta data
COUNT="1"

# Read in and parse $INPUT_FILE by line
while read line; do
  LINE=$line
  ENCLAVE=$( /bin/echo ${LINE} | /usr/bin/cut -d "," -f1  )
  SUBNET=$( /bin/echo ${LINE} | /usr/bin/cut -d "," -f2  )
  IP_ADDR=$( /bin/echo ${LINE} | /usr/bin/cut -d "," -f3  )
  RECORD_TYPE=$( /bin/echo ${LINE} | /usr/bin/cut -d "," -f4  )
  RECORD_ATTR=$( /bin/echo ${LINE} | /usr/bin/cut -d "," -f5  )
    if [[ "${COUNT}" -lt "2" ]]; then
      ## If it is the first interation in the loop, skip adding create line
      let COUNT=${COUNT}+1
    else
      ## Else, add the create line
      /bin/echo -e '{"create" : {"_type" : "'${ES_MAPPER}'", "_id" : "'$( /bin/echo ${COUNT} )'"}}' >> ${JSON_FILE}
      let COUNT=${COUNT}+1
    fi
    ## Add json formated line based on the parsed csv
    /bin/echo -e '{"enclave": "'${ENCLAVE}'", "subnet": "'${SUBNET}'", "ipAddress": "'${IP_ADDR}'", "rcdType": "'${RECORD_TYPE}'", "rcdAttr": "'${RECORD_ATTR}'"}' >> ${JSON_FILE}
done < ${INPUT_FILE}

# Move on to cleanup to prep for es ingest
index_cleanup
}

#infoblox_query() {
# Query dns, return subnets

# Query dns imap repoitory, filter on selected subnet

# Write to CSV format

# Move on to json_builder
  
#}

# If $INPUT_FILE exists, build json from csv
if [[ -f "${INPUT_FILE}" ]]; then json_builder; fi
