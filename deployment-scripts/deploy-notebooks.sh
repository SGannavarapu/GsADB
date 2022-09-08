#!/bin/bash

# Must be run in the directory with the notebooks (spaces in names in Bash can cause issues)
tenant_id=$1
client_id=$2
client_secret=$3
subscription_id=$4
resourceGroup=$5
workspaceName=$6
notebookPathUnderWorkspace=$7

echo "tenant_id : $tenant_id"
echo "client_id : $client_id"
echo "client_secret : $client_secret"
echo "subscription_id : $subscription_id"
echo "resourceGroup : $resourceGroup"
echo "workspaceName : $workspaceName"
echo "notebookPathUnderWorkspace : $notebookPathUnderWorkspace"

# tenant_id="72f988bf-86f1-41af-91ab-2d7cd011db47"
# client_id="e5fc5f4d-f803-44c4-8f2a-92c9a920d226"
# client_secret="-Gc8Q~au_f3lVzosZMDW9u3zcocbXKcbaV_RZcKw"
# subscription_id="011d72ba-8ffe-4358-a191-e5d110d97a2d"
# resourceGroup="Demo-ADB"
# workspaceName="gsdemoadb"
# notebookPathUnderWorkspace="/MyProject"

azure_databricks_resource_id="2ff814a6-3304-4ab8-85cb-cd0e6f879c1d"
resourceId="/subscriptions/$subscription_id/resourceGroups/$resourceGroup/providers/Microsoft.Databricks/workspaces/$workspaceName"


######################################################################################
# Get access tokens for Databricks API
######################################################################################

accessToken="dapi81b00e319c187e4d0a4a973e13d43cab-2"

echo "Databricks accessToken: $accessToken"

######################################################################################
# Get Databricks workspace URL (e.g. adb-5946405904802522.2.azuredatabricks.net)
######################################################################################
workspaceUrl="adb-3185198617161307.7.azuredatabricks.net"
echo "Databricks workspaceUrl: $workspaceUrl"

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
    
    echo "curl https://$workspaceUrl/api/2.0/workspace/mkdirs -d $clusterId --data $JSON"

    curl -X POST https://$workspaceUrl/api/2.0/workspace/mkdirs \
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

        echo "curl -F language=$language -F path=$notebookPathUnderWorkspace/$filename -F content=@$file https://$workspaceUrl/api/2.0/workspace/import"

        curl -n https://$workspaceUrl/api/2.0/workspace/import \
            -H "Authorization:Bearer $accessToken" \
            -F language="$language" \
            -F overwrite=true \
            -F path="$notebookPathUnderWorkspace/$filename" \
            -F content=@"$file"       

        echo ""

    done
