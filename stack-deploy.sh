#!/bin/bash

# Description:

# Deps:
# Java 8+ JDK
# Git client
# local SSH keypair w/ perms to github repo's
#

# Usage: ./stack-deploy.sh <option>
# Options:
#	    dl-pkgs: (download stack dependency repo(s) source into the project parent dir)
#	    build: (build the stack dependency repo(s) source in the project parent dir)
#	    unpack: (extract bundled 'offline' tarballs into the project parent dir)
#	    deploy: (
#	    clean:
#

# Comma delim list of stack component names and versions:
# Syntax: <name1|<ver1>,<name2>|<ver2>
STACK_LIST="elasticsearch|7.16.3,kibana|7.16.3,opensearch|1.2.4,opensearch-security|1.2.4.0"

# Software Versions
JAVA_VER=""

# Base Config
REPO_DIR="es-utils"
DL_DIR="$HOME/proj/downloads"
PROJ_DIR="$HOME/proj/github"
SOFTWARE_DIR="$HOME/proj/software"

mkdir -p ${SOFTWARE_DIR}
mkdir -p ${DL_DIR}
mkdir -p ${PROJ_DIR}

IFS=','
for SPLIT_STACK in ${STACK_LIST}; do
  SELECTED_COMP=$( echo "${SPLIT_STACK}" )
  COMP_NAME=$( echo ${SELECTED_COMP} | cut -d'|' -f1 )
  COMP_VER=$( echo ${SELECTED_COMP} | cut -d'|' -f2 )
  unset IFS

  if [[ "$1" == "dl-pkgs" ]]; then

    # ES/Kibana Stack
    if [[ "${COMP_NAME}" == "elasticsearch" ]] || [[ "${COMP_NAME}" == "kibana" ]]; then
      # https://artifacts.elastic.co/downloads/kibana/kibana-7.17.0-linux-x86_64.tar.gz
      # https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.17.0-linux-x86_64.tar.gz
      wget --no-check-certificate \
          "https://artifacts.elastic.co/downloads/${COMP_NAME}/${COMP_NAME}-${COMP_VER}-linux-x86_64.tar.gz" \
        -O "${DL_DIR}/${COMP_NAME}-${COMP_VER}.tar.gz"
        # renaming the tarball package name for consistency for follow on unpacking
      RET_VAL=${?}
      [[ ${RET_VAL} != 0 ]] && echo "Something went wrong during the artifact download for ${COMP_NAME}." && exit ${RET_VAL}
    fi

    # opensearch security plugin
    if [[ "${COMP_NAME}" == "opensearch-security" ]]; then
      # https://github.com/opensearch-project/security/archive/refs/tags/1.2.4.0.tar.gz
      wget --no-check-certificate \
          "https://github.com/opensearch-project/security/archive/refs/tags/${COMP_VER}.tar.gz" \
        -O "${DL_DIR}/${COMP_NAME}-${COMP_VER}.tar.gz"
      RET_VAL=${?}
      [[ ${RET_VAL} != 0 ]] && echo "Something went wrong during the artifact download for ${COMP_NAME}." && exit ${RET_VAL}
    fi


    # Opensearch Stack
    if [[ "${COMP_NAME}" == "opensearch" ]]; then
      # https://artifacts.opensearch.org/releases/bundle/opensearch/1.2.4/opensearch-1.2.4-linux-x64.tar.gz
      wget --no-check-certificate \
          "https://artifacts.opensearch.org/releases/bundle/${COMP_NAME}/${COMP_VER}/${COMP_NAME}-${COMP_VER}-linux-x64.tar.gz" \
        -O "${DL_DIR}/${COMP_NAME}-${COMP_VER}.tar.gz"
      RET_VAL=${?}
      [[ ${RET_VAL} != 0 ]] && echo "Something went wrong during the artifact download for ${COMP_NAME}." && exit ${RET_VAL}
    fi

  elif [[ "$1" == "deploy" ]]; then

    tar -xzvf ${DL_DIR}/${COMP_NAME}-${COMP_VER}.tar.gz -C ${SOFTWARE_DIR}

    # ensure the extracted component dir name is consistent
    if [[ ! -d "${SOFTWARE_DIR}/${COMP_NAME}-${COMP_VER}" ]]; then
      # search for any bad directory naming matches
      SCAN_BASE_DIR=$( find ${SOFTWARE_DIR} -maxdepth 1 -type d -name '[k]ibana-7.16.3-*' -exec basename "{}" \; )
      if [[ ! -z "${SCAN_BASE_DIR}" ]]; then
        # if NOT null, rename the dir to what we want
        mv "${SOFTWARE_DIR}/${SCAN_BASE_DIR}" "${SOFTWARE_DIR}/${COMP_NAME}-${COMP_VER}"
      fi

      # todo
      # security plugin build to produce zip
      #  reference => https://github.com/opensearch-project/security#test-and-build
      #
      # mvn clean package -Padvanced -DskipTests
      # artifact_zip=`ls $(pwd)/target/releases/opensearch-security-*.zip | grep -v admin-standalone`
      # ./gradlew build buildDeb buildRpm --no-daemon -ParchivePath=$artifact_zip -Dbuild.snapshot=false

    fi

    cd ${SOFTWARE_DIR} && ln -s ${COMP_NAME}-${COMP_VER} ${COMP_NAME}

    if [[ -d "${PROJ_DIR}/${REPO_DIR}/config/${COMP_NAME}" ]]; then
      # parent config dir exists for component, let's copy them over
      # w/ the deployment. by passing the -b flag, a backup of the existing
      # file will be appended with '~' if present in the working directory.
      cp -fpb ${PROJ_DIR}/${REPO_DIR}/config/${COMP_NAME}/*.yml ${SOFTWARE_DIR}/${COMP_NAME}/config/
    else
      echo "no config directory present in baseline to copy. using the default configs.."
    fi

  elif [[ "$1" == "clean" ]]; then

    if [[ -L "${SOFTWARE_DIR}/${COMP_NAME}" ]]; then
      # remove component sym link
      rm -f "${SOFTWARE_DIR}/${COMP_NAME}"
    fi

    if [[ -d "${SOFTWARE_DIR}/${COMP_NAME}-${COMP_VER}" ]]; then
      # remove component directory (w/ version)
      rm -rf "${SOFTWARE_DIR}/${COMP_NAME}-${COMP_VER}"
    fi

    if [[ -f "${DL_DIR}/${COMP_NAME}-${COMP_VER}.tar.gz" ]]; then
      # remove tarball download
      rm -f "${DL_DIR}/${COMP_NAME}-${COMP_VER}.tar.gz"
    fi

  else
    echo "provide a valid option..."
    exit 1
  fi
done

exit 0
