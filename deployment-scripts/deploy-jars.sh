#!/bin/bash

accessToken=$1
workspaceUrl=$2

jarFilePath="dbfs:/FileStore/jars"

######################################################################################
# Create directory for Jar Files
######################################################################################
JSON="{ \"path\" : \"$jarFilePath\" }"

echo "curl $workspaceUrl/api/2.0/dbfs/mkdirs -d $JSON"

curl -X POST $workspaceUrl/api/2.0/dbfs/mkdirs \
    -H "Authorization:Bearer $accessToken" \
    -H "Content-Type: application/json" \
    --data "$JSON"

######################################################################################
# List Directories 
######################################################################################
JSON="{ \"path\" : \"dbfs:/\" }"

echo "curl $workspaceUrl/api/2.0/dbfs/list -d $JSON"

curl -X GET $workspaceUrl/api/2.0/dbfs/list \
    -H "Authorization:Bearer $accessToken" \
    H "Content-Type: application/json" \
    --data "$JSON"

######################################################################################
# Upload Jar Files
######################################################################################
replaceSource="./"
replaceDest=""

find . -type f -name "*" -print0 | while IFS= read -r -d '' file; do
    echo "Processing file: $file"
    filename=${file//$replaceSource/$replaceDest}
    echo "New filename: $filename"

    echo "curl -F path=$filename -F content=@$filename $workspaceUrl/api/2.0/dbfs/put"

    curl -n $workspaceUrl/api/2.0/dbfs/put \
        -H "Authorization:Bearer $accessToken" \
        -F overwrite=true \
        -F path="$jarFilePath/$filename" \
        -F content=@"$filename"       

    echo ""

done

######################################################################################
# List Jar Files
######################################################################################
JSON="{ \"path\" : \"$jarFilePath\" }"

echo "curl $workspaceUrl/api/2.0/dbfs/list -d $JSON"

curl -X GET $workspaceUrl/api/2.0/dbfs/list \
        -H "Authorization:Bearer $accessToken" \
        -H "Content-Type: application/json" \
        --data "$JSON"

echo ""