#!/usr/bin/env python
# coding: utf-8

# ## ETL PROCESS FOR CHADWICK BASEBALL DATA
# This is an ETL process to import data from the Chadwick Databank into a Microsoft SQL Server database, either locally hosted or on AWS.
# https://github.com/chadwickbureau/baseballdatabank
# 
# ## INTENT:
# * become part of AWS lambda job
# * import from S3
# * Deploy schema fresh
# * call SSMS job to do post-import updates
# 
# ### TODO:
# * Integrate native python logging framework
# * EDA.  in SQL?
# * Define schema and key relationships for entire Chadwick db upon import
# * Validation testing on imports -- basic metadata catalog to check on number of rows and full set of tables etc
# * Normalization in SQL post-processing

import pandas as pd
import os.path
import pyodbc
import sqlalchemy
import logging

# migrate me to a config file.
root_dir = "../../baseballdatabank/"

server = "(localdb)\MSSQLLocalDB"
database = "baseball"

engine = sqlalchemy.create_engine("mssql+pyodbc://" + server + "/" + database + "?trusted_connection=yes&driver=ODBC+Driver+17+for+SQL+Server")

# begin the bulk ETL process
subdirs = ["core","contrib"]

with engine.connect() as conn:

    for subdir in subdirs:
        print(subdir)
    
        for i in os.listdir(root_dir + subdir):

            if i.endswith(".csv"):

                file_name = root_dir + subdir + "/" + i
                table_name = subdir + "_" + i.replace(".csv","")

                df = pd.read_csv(file_name)
                
                # didn't realize that inf was an actual valid state for a pandas float
                # infinite ERAs are unfortunate.
                df.replace({np.inf: np.nan, -np.inf: np.nan}, inplace=True)  
                
                # should probably add data validation checks at this step prior to import into sql

                df.to_sql(name=table_name, con=engine, if_exists='replace', index=False)

                print(i + " successfully uploaded.")
