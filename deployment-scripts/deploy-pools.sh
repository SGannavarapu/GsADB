#!/bin/bash

# TO DO
# You might want to Pin your clusters

# Must be run in the directory with the clusters (spaces in names in Bash can cause issues)
tenant_id=$1
client_id=$2
client_secret=$3
subscription_id=$4
resourceGroup=$5
workspaceName=$6
accessToken=$7
workspaceUrl=$8

azure_databricks_resource_id="2ff814a6-3304-4ab8-85cb-cd0e6f879c1d"
resourceId="/subscriptions/$subscription_id/resourceGroups/$resourceGroup/providers/Microsoft.Databricks/workspaces/$workspaceName"

######################################################################################
# Deploy clusters (Add or Update existing)
######################################################################################

replaceSource="./"
replaceDest=""

# Get a list of pool so we know if we need to create or edit
pooList=$(curl GET https://$workspaceUrl/api/2.0/instance-pools/list \
            -H "Authorization:Bearer $accessToken" \
            -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
            -H "Content-Type: application/json")

find . -type f -name "*" -print0 | while IFS= read -r -d '' file; do

    echo "Processing file: $file"
    filename=${file//$replaceSource/$replaceDest}
    echo "New filename: $filename"


    poolName=$(cat $filename | jq -r .instance_pool_name)
    poolId=$(echo $pooList | jq -r ".instance_pools[] | select(.instance_pool_name == \"$poolName\") | .instance_pool_id")

    echo "poolName: $poolName"
    echo "poolId: $poolId"

    # Test for empty cluster id (meaning it does not exist)
    if [ -z "$poolId" ];
    then
       echo "Pool $poolName does not exists in Databricks workspace, Creating..."
       echo "curl https://$workspaceUrl/api/2.0/instance-pools/create -d $filename"

       curl -X POST https://$workspaceUrl/api/2.0/instance-pools/create \
            -H "Authorization:Bearer $accessToken" \
            -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
            -H "Content-Type: application/json" \
            -d @"$filename" 

    else
       echo "Pool $poolName exists in Databricks workspace, Updating..."
       echo "curl https://$workspaceUrl/api/2.0/instance-pools/edit -d $filename"

       # need to inject some JSON into the file
       poolDef=$(cat $filename)

       newJSON=$(echo $poolDef | jq ". += {pool_id: \"$poolId\"}")
       echo "New Cluster Def"
       echo $newJSON
       echo ""

       curl -X POST https://$workspaceUrl/api/2.0/instance-pools/edit \
            -H "Authorization:Bearer $accessToken" \
            -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
            -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
            -H "Content-Type: application/json" \
            --data "$newJSON"

    fi      
    echo ""  

done


# ######################################################################################
# # Sleep will the above calls complete
# ######################################################################################
# read -p "sleeping" -t 15


# ######################################################################################
# # Stop the clusters
# ######################################################################################

# # Get a list of clusters so we know if we need to create or edit
# clusterList=$(curl GET https://$workspaceUrl/api/2.0/clusters/list \
#                -H "Authorization:Bearer $accessToken" \
#                -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
#                -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
#                -H "Content-Type: application/json")

# find . -type f -name "*" -print0 | while IFS= read -r -d '' file; do
#     echo "Processing file: $file"
#     filename=${file//$replaceSource/$replaceDest}
#     echo "New filename: $filename"

#     clusterName=$(cat $filename | jq -r .cluster_name)
#     clusterId=$(echo $clusterList | jq -r ".clusters[] | select(.cluster_name == \"$clusterName\") | .cluster_id")

#     echo "clusterName: $clusterName"
#     echo "clusterId: $clusterId"

#     # Test for empty cluster id (meaning it does not exist)
#     if [ -z "$clusterId" ];
#     then
#        echo "WARNING: Cluster $clusterName did not have a Cluster Id.  Stopping the cluster will not occur."

#     else
#        echo "Cluster $clusterName with Cluster ID $clusterId, Stopping..."
#        echo "curl https://$workspaceUrl/api/2.0/clusters/delete -d $clusterId"

#        newJSON="{ \"cluster_id\" : \"$clusterId\" }"
#        echo "Cluster to stop: $newJSON"
   
#        # NOTE: permanent-delete is used to "delete" the cluster.  Delete below means "stop" the clustter
#        curl -X POST https://$workspaceUrl/api/2.0/clusters/delete \
#             -H "Authorization:Bearer $accessToken" \
#             -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
#             -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
#             -H "Content-Type: application/json" \
#             --data "$newJSON"
#     fi     
#     echo ""  

# done
