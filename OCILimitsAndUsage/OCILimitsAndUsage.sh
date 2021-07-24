#!/usr/bin/bash
#####################################################################################
#
# Overview: This shell outputs csv of the Service Limits and Usage in the OCI tenant.
# Pre-requirement1. Have the OCI CLI installed.
# Pre-requirement2. Make OCI CLI ready to run through the path.
# Pre-requirement3. Complete the configuration(oci setup config).
#
# Usage: ./OCILimitsAndUsage.sh $1 $2 $3
# $1 ... OCI CLI configration file full path
# $2 ... Compartment OCID
# $3 ... Tenancy Name
#
# Example: ./OCILimitsAndUsage.sh /home/opc/.oci/config ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxxxxx admin2
#
#####################################################################################

# Get Region Name List
function GetRegionNameList() {
  oci iam region-subscription list | jq -r '.data[]|[."region-name"]|@csv' | tr -d '"' > ${REGION_NAME_LIST}
  return 0;
}

# Get Service Name List
function GetServiceNameList() {
  REGION_NAME=$1
  oci limits definition list -c ${COMPARTMENT_OCID} --all --region ${REGION_NAME} | jq -r '.data[]|[."service-name"]|@csv' | sort -u > ${SERVICE_NAME_LIST}
  return 0;
}

# Get Limit Name List
function GetLimitNameList() {
  REGION_NAME=$1
  cat ${SERVICE_NAME_LIST} | while read -r SERVICE_NAME
  do
    SERVICE_NAME2=`echo ${SERVICE_NAME} | tr -d '"'`
    oci limits value list -c ${COMPARTMENT_OCID} --service-name ${SERVICE_NAME2} --all  --region ${REGION_NAME} | jq -r '.data[]|[."availability-domain", ."name", ."value"]|@csv' > ${LIMIT_NAME_LIST_TMP}
    cat ${LIMIT_NAME_LIST_TMP} | sed "s/^,/\"\",/" | sed -e "s/^/${SERVICE_NAME},/" >> ${LIMIT_NAME_LIST}
  done;
  return 0;
}

# Get Limits and Usage
function GetLimitsAndUsage() {
  REGION_NAME=$1
  DATETIME=`date +"%Y%m%d,%H%M%S"`
  cat ${LIMIT_NAME_LIST} | sed "s/,/ /g" | while read -r SERVICE_NAME AD_NAME LIMIT_NAME LIMIT_VALUE
  do
    SERVICE_NAME2=`echo ${SERVICE_NAME} | tr -d '"'`
    AD_NAME2=`echo ${AD_NAME} | tr -d '"'`
    LIMIT_NAME2=`echo ${LIMIT_NAME} | tr -d '"'`
    LIMIT_VALUE2=`echo ${LIMIT_VALUE} | tr -d '"'`
    if [ "${AD_NAME}" = '""' ] ; then
      # echo "AD is empty."
      oci limits resource-availability get --compartment-id ${COMPARTMENT_OCID} --limit-name ${LIMIT_NAME2} --service-name ${SERVICE_NAME2} --region ${REGION_NAME} | jq -r '.data|[."available", ."used"]|@csv' > ${LIMIT_USAGE_TMP}
      cat ${LIMIT_USAGE_TMP} | sed "s/^/${DATETIME},${TENANCY_NAME},${REGION_NAME},${SERVICE_NAME2},${AD_NAME2},${LIMIT_NAME2},${LIMIT_VALUE2},/" >> ${LIMIT_USAGE_CSV}
    else
      # echo "AD is not empty."
      oci limits resource-availability get --compartment-id ${COMPARTMENT_OCID} --limit-name ${LIMIT_NAME2} --service-name ${SERVICE_NAME2} --availability-domain ${AD_NAME2} --region ${REGION_NAME} | jq -r '.data|[."available", ."used"]|@csv' > ${LIMIT_USAGE_TMP}
      cat ${LIMIT_USAGE_TMP} | sed "s/^/${DATETIME},${TENANCY_NAME},${REGION_NAME},${SERVICE_NAME2},${AD_NAME2},${LIMIT_NAME2},${LIMIT_VALUE2},/" >> ${LIMIT_USAGE_CSV}
    fi;
done;
}

# Parameter Check
if [ -z "$1" -o -z "$2" -o -z "$3" ] ; then
  echo "Usage: ./OCILimitsAndUsage.sh \$1 \$2 \$3";
  exit 1;
fi;

# Initialize
export OCI_CLI_RC_FILE=$1
export COMPARTMENT_OCID=$2
export TENANCY_NAME=$3
export REGION_NAME_LIST="${TENANCY_NAME}_region_name_list.csv"
export SERVICE_NAME_LIST="${TENANCY_NAME}_servie_name_list.csv"
export LIMIT_NAME_LIST="${TENANCY_NAME}_limit_name_list.csv"
export LIMIT_NAME_LIST_TMP="${TENANCY_NAME}_limit_name_list_tmp.tmp"
export LIMIT_USAGE_TMP="${TENANCY_NAME}_limit_usage.tmp"

: > ${REGION_NAME_LIST}
: > ${SERVICE_NAME_LIST}
: > ${LIMIT_NAME_LIST}
: > ${LIMIT_NAME_LIST_TMP}
: > ${LIMIT_USAGE_TMP}

# CSV file initialize
export DATETIME2=`date +"%Y%m%d_%H%M%S"`
export LIMIT_USAGE_CSV="${DATETIME2}_${TENANCY_NAME}_limit_usage.csv"
echo "DATE,TIME,TENANCY_NAME,REGION_NAME,SERVICE_NAME,AVAILABILITY_DOMAIN,LIMIT_NAME,LIMITS,AVAILABLE,USED" > ${LIMIT_USAGE_CSV}

# Get Region Name List
GetRegionNameList

# Get Limit and Usage in the All-Region
cat ${REGION_NAME_LIST} | while read -r REGION_NAME
do
  # Initialize
  : > ${SERVICE_NAME_LIST}
  : > ${LIMIT_NAME_LIST}
  : > ${LIMIT_NAME_LIST_TMP}
  : > ${LIMIT_USAGE_TMP}
  # Get Service Name List
  GetServiceNameList ${REGION_NAME}

  # Get Limit Name List
  GetLimitNameList ${REGION_NAME}

  # Get Limits and Usage
  GetLimitsAndUsage ${REGION_NAME}
done;

# Finalize
rm ${REGION_NAME_LIST}
rm ${SERVICE_NAME_LIST}
rm ${LIMIT_NAME_LIST}
rm ${LIMIT_NAME_LIST_TMP}
rm ${LIMIT_USAGE_TMP}

exit 0;
