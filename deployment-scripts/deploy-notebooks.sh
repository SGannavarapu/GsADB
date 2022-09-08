#!/bin/bash

# Must be run in the directory with the notebooks (spaces in names in Bash can cause issues)
tenant_id="72f988bf-86f1-41af-91ab-2d7cd011db47"
client_id="e5fc5f4d-f803-44c4-8f2a-92c9a920d226"
client_secret="-Gc8Q~au_f3lVzosZMDW9u3zcocbXKcbaV_RZcKw"
subscription_id="011d72ba-8ffe-4358-a191-e5d110d97a2d"
resourceGroup="Demo-ADB"
workspaceName="gsdemoadb"
notebookPathUnderWorkspace="/MyProject"

# azure_databricks_resource_id="2ff814a6-3304-4ab8-85cb-cd0e6f879c1d"
resourceId="/subscriptions/$subscription_id/resourceGroups/$resourceGroup/providers/Microsoft.Databricks/workspaces/$workspaceName"


######################################################################################
# Get access tokens for Databricks API
######################################################################################

accessToken=$(curl -X POST https://login.microsoftonline.com/$tenant_id/oauth2/token \
  -F resource=$azure_databricks_resource_id \
  -F client_id=$client_id \
  -F grant_type=client_credentials \
  -F client_secret=$client_secret | jq .access_token --raw-output) 

managementToken=$(curl -X POST https://login.microsoftonline.com/$tenant_id/oauth2/token \
  -F resource=https://management.core.windows.net/ \
  -F client_id=$client_id \
  -F grant_type=client_credentials \
  -F client_secret=$client_secret | jq .access_token --raw-output) 


######################################################################################
# Get Databricks workspace URL (e.g. adb-5946405904802522.2.azuredatabricks.net)
######################################################################################
# workspaceUrl=$(curl -X GET \
#         -H "Content-Type: application/json" \
#         -H "Authorization: Bearer $managementToken" \
#         https://management.azure.com/subscriptions/$subscription_id/resourcegroups/$resourceGroup/providers/Microsoft.Databricks/workspaces/$workspaceName?api-version=2018-04-01 \
#         | jq .properties.workspaceUrl --raw-output)
workspaceUrl="https://adb-3185198617161307.7.azuredatabricks.net"
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
        -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
        -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
        -H "Content-Type: application/json" \
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
            -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
            -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
            -F language="$language" \
            -F overwrite=true \
            -F path="$notebookPathUnderWorkspace/$filename" \
            -F content=@"$file"       

        echo ""

    done
