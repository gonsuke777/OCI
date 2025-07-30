#!/usr/bin/bash

# ---
# This script uploads Linux file system usage as OCI custom metric by the OCI CLI.
# It must be able to run the OCI CLI beforehand.
# Targets xfs and ext4. It's excluded for nfs etc and /boot.
# Please edit in this shell environment variables. PATH, workfile, jsonfile, etc.
# ---
# Usage Example ... $ ./OCIFileSystemUsage.sh
# Parameters    ... Not required
# Return Code
#   0 ... Successful completion.
#   1 ... abend.
# ---

# Initialize
LANG=en_US.UTF-8
PATH=/home/opc/bin:/home/opc/.local/bin:/home/opc/bin:/usr/share/Modules/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin
mypath=$(dirname "${0}")
cliLocation="/usr/bin/oci"
workfile="${mypath}/filesystemusage_work.txt"
jsonfile="${mypath}/filesystemusage_work.json"

# OCI env initialize
compartmentId=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/ | jq -r '.compartmentId')
metricNamespace="compute_filesystem_usage"
metricResourceGroup="compute_filesystem_usage_rg"
instanceName=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/ | jq -r '.displayName')
instanceId=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/ | jq -r '.id')
endpointRegion=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/ | jq -r '.canonicalRegionName')
Timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# Upload custom metric function
# $1...mountPoint
# $2...Usage
function UploadCustomMetric () {
  metricsJson=$(cat << EOF > ${jsonfile}
[
   {
      "namespace":"${metricNamespace}",
      "compartmentId":"${compartmentId}",
      "resourceGroup":"${metricResourceGroup}",
      "name":"FileSystemUsage",
      "dimensions":{
         "mountPoint":"$1",
         "instanceName":"${instanceName}"
      },
      "metadata":{
         "unit":"Percent",
         "displayName":"FilesystemUsage"
      },
      "datapoints":[
         {
            "timestamp":"${Timestamp}",
            "value":"$2"
         }
      ]
   }
]
EOF
  )
  # for debug.
  cat ${jsonfile};
  echo ${cliLocation} monitoring metric-data post --metric-data file://${jsonfile} --endpoint https://telemetry-ingestion.${endpointRegion}.oraclecloud.com --auth instance_principal
  # Upload custom metric by the OCI CLI. 
  ${cliLocation} monitoring metric-data post --metric-data file://${jsonfile} --endpoint https://telemetry-ingestion.${endpointRegion}.oraclecloud.com --auth instance_principal
}

# Output filesystem information to workfile, xfs or ext4 only, exclude /boot and header.
Timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
df --type=xfs --type=ext4 | grep -Ev "^Filesystem" > ${workfile}
if [ $? -eq 0 ]
then
  echo "no error df."; 
else
  #If error occured, dummy metric upload.
  UploadCustomMetric error -1;
  # abend.
  echo "error in df."; 
  exit 1;
fi

# Upload custom metric per mountPoint.
IFS=$'\n'
for line in $(cat ${workfile})
do
  Usage=$(echo $line | awk '{print $5}' | sed 's/%//')
  mountPoint=$(echo $line | awk '{print $6}')
  # for debug.
  echo ${Usage}
  echo ${mountPoint}
  # Call upload custom metric function.
  UploadCustomMetric "${mountPoint}" "${Usage}"
done

# Successful completion.
exit 0;
