#!/bin/bash

###
### You should not have to modify anything below here
###

usage() {
  cat << USAGE
cut-release.sh -- simple content view management for Satellite 6

Usage:

  cut-release.sh [options]

Options:
        -d                  Enable debugging to see WTF is happening
        -f [lifecycle]      When promoting content views, this is the FROM lifecycle
        -h, --help          Show this message
        -o [organization]   (required) Specify the Satellite 6 organization
        -p                  Publish new content views to the Library
        -P                  Promote content view versions to a lifecycle
                            You must specify the -f and -t options to promote
        -t [lifecycle]      When promoting content views, this is the TO lifecycle
        -x [number]         Keep num of versions older than the PURGE lifecycle

        -X [lifecycle]      Purge versions older than the one assigned to PURGE lifecycle

Environment Variables:

Options can also be specified as environment variables instead, making
integration with CI/CD tools such as Jenkins easier.

        DEBUG              true/false
        ORG                "Default_Organization"
        PUBLISH_VERSION    true/false
        PROMOTE_VERSION    true/false
          FROM_LIFECYCLE   "From_Lifecycle"
          TO_LIFECYCLE     "To_Lifecycle"
        PURGE_VERSIONS     true/false
          PURGE_LIFECYCLE  "Purge_Lifecycle"

Examples:

  To publish a new version of all content views to the "Library" lifecycle
  environment:

    # cut-release.sh -o "Default_Organization" -p

  To promote the version of all content views in the "Library" lifecyle to
  the "Development" lifecycle environment:

    # cut-release.sh -o "Default_Organization" -P -f "Library" -t "Development"

  To publish a new version of all content views to the "Library" lifecycle and
  immediately promote to the "Development" lifecycle environment:

    # cut-release.sh -o "Default_Organization" -p -P -f "Library" -t "Development"

USAGE
}

while getopts "df:ho:pPt:x:X:" opt; do
  case $opt in
    d)
      DEBUG="true"
      HAMMER_OPTS="-d -v"
      ;;
    f)
      FROM_LIFECYCLE="$OPTARG"
      ;;
    h)
      usage
      exit 1
      ;;
    o)
      ORG="$OPTARG"
      ;;
    p)
      PUBLISH_VERSION="true"
      ;;
    P)
      PROMOTE_VERSION="true"
      ;;
    t)
      TO_LIFECYCLE="$OPTARG"
      ;;
    x)
      PURGE_KEEP_EXTRA=${OPTARG}
      ;;
    X)
      PURGE_VERSIONS="true"
      PURGE_LIFECYCLE="${OPTARG}"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

DEBUG=${DEBUG:-false}
ORG=${ORG:?Organization is required!}
PUBLISH_VERSION=${PUBLISH_VERSION:-false}
PROMOTE_VERSION=${PROMOTE_VERSION:-false}
PURGE_VERSIONS=${PURGE_VERSIONS:-false}
PURGE_KEEP_EXTRA=${PURGE_KEEP_EXTRA:-0}

if [ "$DEBUG" = "true" ]; then
  echo "----"
  echo "DEBUG              = ${DEBUG}"
  echo "ORG                = ${ORG}"
  echo "PUBLISH_VERSION    = ${PUBLISH_VERSION}"
  echo "PROMOTE_VERSION    = ${PROMOTE_VERSION}"
  echo "  FROM_LIFECYCLE   = ${FROM_LIFECYCLE:-none}"
  echo "  TO_LIFECYCLE     = ${TO_LIFECYCLE:-none}"
  echo "PURGE_VERSIONS     = ${PURGE_VERSIONS}"
  echo "  PURGE_LIFECYCLE  = ${PURGE_LIFECYCLE:-none}"
  echo "  PURGE_KEEP_EXTRA = ${PURGE_KEEP_EXTRA}"
fi

TODAY=$(date +%Y-%m-%d)

CONTENT_VIEWS=$(hammer ${HAMMER_OPTS} --output=csv content-view list \
                --organization="${ORG}" | tail -n +2)

O_IFS=$IFS
IFS=$'\n'

for CV in ${CONTENT_VIEWS}; do
  CV_ID=$(echo ${CV} | cut -d , -f 1)
  CV_NAME=$(echo ${CV} | cut -d , -f 2)

  if [ ${CV_ID} -eq 1 ]; then
    echo "Skipping [${CV_NAME}] with id ${CV_ID}"
    continue
  fi

  if [ "${PUBLISH_VERSION}" = "true" ]; then
    echo "Publishing a new version of content view [${CV_NAME}] with id ${CV_ID}"
    hammer ${HAMMER_OPTS} content-view publish \
      --organization="${ORG}" \
      --id=${CV_ID} \
      --description="Publishing new version on ${TODAY} - see ${BUILD_URL}"
  fi

  # If we specified the to/from lifecycle environments
  if [ "${PROMOTE_VERSION}" = "true" ]; then
    FROM_LIFECYCLE=${FROM_LIFECYCLE:?FROM_LIFECYCLE is required!}
    TO_LIFECYCLE=${TO_LIFECYCLE:?TO_LIFECYCLE is required!}

    CV_VERSION=$(hammer ${HAMMER_OPTS} --output=csv content-view version list \
                --organization="${ORG}" \
                --environment="${FROM_LIFECYCLE}" \
                --content-view-id=${CV_ID} \
                | tail -n +2 | head -n 1)

    CV_VERSION_ID=$(echo ${CV_VERSION} | cut -d , -f 1)
    CV_VERSION_NAME=$(echo ${CV_VERSION} | cut -d , -f 2)

    echo "Promoting [${CV_VERSION_NAME}] with id ${CV_VERSION_ID} from [${FROM_LIFECYCLE}] to [${TO_LIFECYCLE}]"
    hammer ${HAMMER_OPTS} content-view version promote \
      --organization="${ORG}" \
      --content-view-id=${CV_ID} \
      --from-lifecycle-environment="${FROM_LIFECYCLE}" \
      --to-lifecycle-environment="${TO_LIFECYCLE}" \
      --id=${CV_VERSION_ID}

    echo "Installable erratum for [${CV_VERSION_NAME}] content hosts"
    hammer ${HAMMER_OPTS} erratum list \
      --organization="${ORG}" \
      --content-view-id=${CV_ID} \
      --content-view-version-id=${CV_VERSION_ID} \
      --errata-restrict-installable=true
  fi

  # If we specified the to/from lifecycle environments
  if [ "${PURGE_VERSIONS}" = "true" ]; then
    PURGE_LIFECYCLE=${PURGE_LIFECYCLE:?PURGE_LIFECYCLE is required!}

    if [ "${PURGE_KEEP_EXTRA}" -lt "0" ]; then
      echo "PURGE_KEEP_EXTRA must be a number > 0"
      exit 1
    fi

    echo "Purging content view [${CV_NAME}] for versions older than lifecycle [${PURGE_LIFECYCLE}]"

    CV_VERSIONS=$(hammer ${HAMMER_OPTS} --output=csv content-view version list \
                --organization="${ORG}" \
                --content-view-id=${CV_ID} \
                | tail -n +2)

    CV_LIFECYCLE_LINE=$(echo "${CV_VERSIONS}" | grep -n -m 1 ${PURGE_LIFECYCLE} | cut -f 1 -d :)

    CV_PURGE_LINE=$(expr ${CV_LIFECYCLE_LINE} + ${PURGE_KEEP_EXTRA} + 1)

    CV_PURGE_VERSIONS=$(echo "${CV_VERSIONS}" | tail -n +${CV_PURGE_LINE})

    for CV_PURGE_VERSION in ${CV_PURGE_VERSIONS}; do
      CV_VERSION_ID=$(echo "${CV_PURGE_VERSION}" | cut -d , -f 1)
      CV_VERSION_NAME=$(echo "${CV_PURGE_VERSION}" | cut -d , -f 2)

      echo "Purging version [${CV_VERSION_NAME}] with id ${CV_VERSION_ID}"
      hammer ${HAMMER_OPTS} content-view version delete \
        --organization="${ORG}" \
        --content-view-id=${CV_ID} \
        --id=${CV_VERSION_ID}
    done
  fi

done

IFS=$O_IFS
