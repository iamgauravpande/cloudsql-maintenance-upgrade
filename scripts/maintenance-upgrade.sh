#!/bin/bash

PRESENT_DATESTR=`/bin/date --date="" '+%Y-%m-%d'`
export PRESENT_DATESTR


MAINTENANCE_0_FLAG="/home/lostinopensrc/maintenance_0_flag.txt"
export MAINTENANCE_0_FLAG

# Deny maintenance window for 90 days
DENY_PERIOD_DAYS=90

DENY_START_DATE=$(date +'%Y-%m-%d')
DENY_END_DATE=$(date -d "+${DENY_PERIOD_DAYS} days" +'%Y-%m-%d')
DENY_TIME=$(date -u +'%H:%M:%S' -d 'today 00:00:00')


availableMaintenanceVersions=`gcloud sql instances describe homelab-pg01  --flatten=availableMaintenanceVersions | grep  -w "availableMaintenanceVersions" | cut -d ":" -f 2 | cut -d " " -f 2`
maintenanceVersion=`gcloud sql instances describe homelab-pg01  | grep -w "maintenanceVersion" | cut -d ":" -f 2 | cut -d " " -f 2`

if [ ! -z "$availableMaintenanceVersions" ]
then
  if [ ! -f $MAINTENANCE_0_FLAG ]
   then
      if [ "$availableMaintenanceVersions" != "$maintenanceVersion" ];then
         touch $MAINTENANCE_0_FLAG
         status=`curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"Version change detected from $maintenanceVersion to $availableMaintenanceVersions time to Plan Maintainance for Instance homelab-pg01\"}" $WEBHOOK_URL`
         echo "Date: `/bin/date` Version change detected from $maintenanceVersion to $availableMaintenanceVersions time to Plan Maintainance for instance homelab-pg01"
         gcloud sql instances patch homelab-pg01 --deny-maintenance-period-start-date="${DENY_START_DATE}" --deny-maintenance-period-end-date="${DENY_END_DATE}" --deny-maintenance-period-time="${DENY_TIME}"
         sleep 5s
         gcloud sql instances describe homelab-pg01 |  grep  denyMaintenancePeriods -A2 | grep -E "endDate|startDate" | awk '{$1=$1};1' > /home/lostinopensrc/deny_maintenance_window_0.txt
         sleep 3s
         curl -F file="@/home/lostinopensrc/deny_maintenance_window_0.txt" -F "initial_comment=Placed 90 days Deny Maintenance Window for Instance: homelab-pg01 now patching to latest Maintenance Version" -F channels="homelab" -H "Authorization:Bearer $BOT_TOKEN" https://slack.com/api/files.upload
         gcloud sql instances patch homelab-pg01 --maintenance-version="${availableMaintenanceVersions}"
         sleep 6m
         postPatchAvailableMaintenanceVersions=`gcloud sql instances describe homelab-pg01  --flatten=availableMaintenanceVersions | grep  -w "availableMaintenanceVersions" | cut -d ":" -f 2 | cut -d " " -f 2`
         if [ -z "$postPatchAvailableMaintenanceVersions" ];then
           if [ -f $MAINTENANCE_0_FLAG ];then
             status=`curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"Maintenance Version is up-to-date now for instance homelab-pg01\"}" $WEBHOOK_URL`
             echo "Date: `/bin/date` Maintenance Version is up-to-date now for instance homelab-pg01"
             rm -rf $MAINTENANCE_0_FLAG
           fi
         fi             
      fi
  fi
fi