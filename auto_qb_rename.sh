#!/bin/bash

# Description:
#
# Author: Sage
# Email: sagehou@outlook.com
# Version: 1.0
# CreateTime: 2022-6-10 15:47:45

if [[ "${sonarr_eventtype}" != "Grab" ]]; then
  echo "[Auto_QB_Rename] Sonarr Event Type is NOT Grab, exiting."
  exit
fi

QB_URL=http://
QB_USERNAME=
QB_PASSWORD=

COOKIE=$(curl -i -s --header "Referer: ${QB_URL}" --data-urlencode "username=${QB_USERNAME}" --data-urlencode "password=${QB_PASSWORD}" ${QB_URL}/api/v2/auth/login | grep "set-cookie:" | cut -d';' -f1 | cut -d':' -f2)

if [ -n ${COOKIE} ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 登录成功! cookie:${COOKIE}" > /dev/stdout
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 登录失败！" > /dev/stderr
    exit
fi

# Get filename of the torrent.
OLD_PATH=`curl -s ${QB_URL}/api/v2/torrents/info?hashes=${sonarr_download_id} --cookie ${COOKIE} | jq '.[].name' | sed  's/"//g' | sed "s/\'//g"`

# Get file type of the job.
MEDIA_TYPE=`curl -s ${QB_URL}/api/v2/torrents/info?hashes=${sonarr_download_id} --cookie ${COOKIE} | jq '.[].name' | sed  's/"//g' | sed "s/\'//g" | awk -F. '{print $NF}'`

# Will be modified to name.
#NEW_PATH="["${sonarr_release_releasegroup}"] "${sonarr_release_title}"."${MEDIA_TYPE}
NEW_PATH=${sonarr_release_title}"."${MEDIA_TYPE}

# Log.
echo "oldPath: ""${OLD_PATH} ""\n""newPath: " "${NEW_PATH}" > /dev/stderr

ENCODED_OLD_PATH=$(echo ${OLD_PATH} | tr -d '\n' | od -An -tx1 | tr ' ' % | tr -d '\n')

ENCODED_NEW_PATH=$(echo ${NEW_PATH} | tr -d '\n' | od -An -tx1 | tr ' ' % | tr -d '\n')

CURL_DATA=\'"hash="${sonarr_download_id}"&oldPath="${ENCODED_OLD_PATH}"&newPath="${ENCODED_NEW_PATH}\'

echo "curlData: ""${CURL_DATA}" > /dev/stdout

# Call QB Rename API
echo "#!/bin/bash" > /tmp/tmpscripts.sh
echo "sleep 10 && /usr/bin/curl -s ${QB_URL}/api/v2/torrents/renameFile --data-raw ${CURL_DATA} --cookie ${COOKIE}" >> /tmp/tmpscripts.sh
/bin/bash /tmp/tmpscripts.sh > /dev/stdout &