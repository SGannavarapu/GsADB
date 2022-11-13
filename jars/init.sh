%sh
#!/bin/bash
rm -rf /databricks/jars/ordersystem.jar
cp /dbfs/<path_to_replacement_jar>/<replacement_jar_filename>.jar /databricks/jars/

rm -rf /databricks/jars/crmsystem.jar
cp /dbfs/<path_to_replacement_jar>/<replacement_jar_filename>.jar /databricks/jars/

echo library installed
# cp /dbfs/FileStore/jars/*.jar /databricks/jars/
# %sh

# #!/bin/bash
# rm -rf /databricks/jars/<jar_filename_to_remove>.jar
# cp /dbfs/<path_to_replacement_jar>/<replacement_jar_filename>.jar /databricks/jars/