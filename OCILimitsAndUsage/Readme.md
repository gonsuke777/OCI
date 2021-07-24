# Overview
* This shell outputs csv of the Service Limits and Usage in the OCI tenant.

# Pre-requirements
* Have the OCI CLI installed.
* Complete the configuration(oci setup config).
* Make OCI CLI ready to run through the path.

# Usage:

```sh
./OCILimitsAndUsage.sh $1 $2 $3
```
* $1 ... OCI CLI configration file full path
* $2 ... Compartment OCID
* $3 ... Tenancy Name(Any String)

```sh
# Example
./OCILimitsAndUsage.sh /home/opc/.oci/config ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxxxxx ayutenant
```

# Output
The following CSV file will be output.
```SQL
DATE,TIME,TENANCY_NAME,REGION_NAME,SERVICE_NAME,AVAILABILITY_DOMAIN,LIMIT_NAME,LIMITS,AVAILABLE,USED
：
20210724,055749,ayutenant,us-ashburn-1,compute,tQtc:US-ASHBURN-AD-1,standard-e3-core-ad-count,600,600,0
20210724,055749,ayutenant,us-ashburn-1,compute,tQtc:US-ASHBURN-AD-2,standard-e3-core-ad-count,600,600,0
20210724,055749,ayutenant,us-ashburn-1,compute,tQtc:US-ASHBURN-AD-3,standard-e3-core-ad-count,600,600,0
20210724,055749,ayutenant,us-ashburn-1,compute,tQtc:US-ASHBURN-AD-1,standard-e3-core-count-reservable,0,0,0
20210724,055749,ayutenant,us-ashburn-1,compute,tQtc:US-ASHBURN-AD-2,standard-e3-core-count-reservable,0,0,0
20210724,055749,ayutenant,us-ashburn-1,compute,tQtc:US-ASHBURN-AD-3,standard-e3-core-count-reservable,0,0,0
：
```