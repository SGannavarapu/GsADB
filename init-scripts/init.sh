#!/bin/bash
%sh
echo "Init-Script Started"


#!/bin/bash
rm -rf /databricks/jars/ordersystem.jar
rm -rf /databricks/jars/crmsystem.jar
cp /dbfs/FileStore/jars/*.jar /databricks/jars/

echo "library installed"

echo "Executing this code on drivers and workers"

echo "Init-Script Completed"