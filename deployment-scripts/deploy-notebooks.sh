#!/bin/bash

# Must be run in the directory with the notebooks (spaces in names in Bash can cause issues)
# tenant_id=$1
# client_id=$2
# client_secret=$3
# subscription_id=$4
# resourceGroup=$5
# workspaceName=$6
notebookPathUnderWorkspace=$1
accessToken=$2
workspaceUrl=$3

# echo "tenant_id : $tenant_id"
# echo "client_id : $client_id"
# echo "client_secret : $client_secret"
# echo "subscription_id : $subscription_id"
# echo "resourceGroup : $resourceGroup"
# echo "workspaceName : $workspaceName"
echo "notebookPathUnderWorkspace : $notebookPathUnderWorkspace"
echo "accessToken : $accessToken"
echo "workspaceUrl : $workspaceUrl"

# azure_databricks_resource_id="2ff814a6-3304-4ab8-85cb-cd0e6f879c1d"

######################################################################################
# Recusively Create Paths 
######################################################################################
replaceSource="./"
replaceDest=""

find . -type d -name "*" -print0 | while IFS= read -r -d '' dirPath; do
    echo "Processing directory: $dirPath"
    directoryName=${dirPath//$replaceSource/$replaceDest}
    echo "New directoryName: $directoryName"

    if [[ "$dirPath" = "." ]];
    then
        pathOnDatabricks=$notebookPathUnderWorkspace
    else
        pathOnDatabricks="$notebookPathUnderWorkspace/$directoryName"
    fi
    echo "pathOnDatabricks: $pathOnDatabricks"

    JSON="{ \"path\" : \"$pathOnDatabricks\" }"
    echo "Creating Path: $JSON"
    
    echo "curl $workspaceUrl/api/2.0/workspace/mkdirs -d $clusterId --data $JSON"

    curl -X POST $workspaceUrl/api/2.0/workspace/mkdirs \
        -H "Authorization:Bearer $accessToken" \
       --data "$JSON"
done

######################################################################################
# Deploy notebooks (resursively)
######################################################################################

    find $dirPath -type f -name "*" -print0 | while IFS= read -r -d '' file; do
        echo "Processing file: $file"
        filename=${file//$replaceSource/$replaceDest}
        echo "New filename: $filename"

        language=""
        if [[ "$filename" == *sql ]]
        then
            language="SQL"
        fi

        if [[ "$filename" == *scala ]]
        then
            language="SCALA"
        fi

        if [[ "$filename" == *py ]]
        then
            language="PYTHON"
        fi

        if [[ "$filename" == *r ]]
        then
            language="R"
        fi

        echo "curl -F language=$language -F path=$notebookPathUnderWorkspace/$filename -F content=@$file $workspaceUrl/api/2.0/workspace/import"

        curl -n $workspaceUrl/api/2.0/workspace/import \
            -H "Authorization:Bearer $accessToken" \
            -F language="$language" \
            -F overwrite=true \
            -F path="$notebookPathUnderWorkspace/$filename" \
            -F content=@"$file"       

        echo ""

    done
