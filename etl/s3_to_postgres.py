#!/usr/bin/env python
# coding: utf-8

# ## ETL PROCESS FOR CHADWICK BASEBALL DATA
# This is an ETL process to import data from the Chadwick Databank Postgres database, either locally hosted or on AWS.
# https://github.com/chadwickbureau/baseballdatabank ---> this has been deprecated.
# next step: switch back to lahman vanilla.  reimport into AWS S3.
# 
# ## INTENT:
# * Python orchestrator using SQL supplement scripts
# * import from S3
# * Deploy schema fresh
# 
# ### TODO:
# * Engine vs connection in SQLAlchemy ---> Use Connection for sql procs etc, make sure to wrap in a transaction.
# * ~Integrate native python logging framework~
# * EDA.  in SQL?
# * learn PSQL?
# * Define schema and key relationships for entire Chadwick db upon import
# * Validation testing on imports -- basic metadata catalog to check on number of rows and full set of tables etc
# * Normalization in SQL post-processing
# 
# * parameterize me so we're not running the same thing repeatedly.  add command line args.  sys.argv, sys.argparse

import logging
import sys

import pandas as pd
import os.path
import numpy as np

from sqlalchemy import create_engine
from sqlalchemy import text

logging.basicConfig(level=logging.DEBUG,
                    format="%(asctime)s [%(levelname)s] %(message)s",
                    handlers=[  
                        logging.FileHandler("./logs/etl.log"),
                        logging.StreamHandler(sys.stdout)
                    ]
)

# config namespace -- migrate me to a config soon please
data_dir = "../../baseballdatabank/"
schema_dir = "../schema/"
tables_dir = "../schema/tables/"

iso_country_file_name = "../data/wikipedia-iso-country-codes.csv"
state_province_file_name = "../data/cdh_state_codes.txt"

user_name = 'test'
password = 'test' ## super secure!
db_server = 'localhost:5433'
db_name = 'baseball_test'

conn_string = 'postgresql+psycopg2://' + user_name + ':' + password + '@' + db_server + '/' + db_name
engine = create_engine(conn_string)

# ISO codes (pulled from https://www.kaggle.com/datasets/juanumusic/countries-iso-codes)
with engine.connect() as conn:
    logging.info('Importing ISO Code Country Data...')
    df = pd.read_csv(iso_country_file_name)
    df.to_sql(name='misc_CountryCode'
                ,schema='stg'
                ,con=engine
                ,if_exists='replace'
                ,index=False)

    logging.info("Complete.")

    # State and Province Data courtesy of https://gist.github.com/mindplay-dk/4755200
    logging.info('Importing State and Province Data...')
    df = pd.read_csv(state_province_file_name, sep="\t")
    df.to_sql(name='misc_states'
                ,schema='stg'
                ,con=engine
                ,if_exists='replace'
                ,index=False)

    logging.info("Complete.")

# begin the bulk ETL process of chadwick data
subdirs = ["core","contrib"]

with engine.connect() as conn:

    # with Session.begin() as session:
    #     with open(schema_dir + "Create stg Schema.sql") as file:
    #         query = text(file.read())
    #         conn.execute(query)

    for subdir in subdirs:
        logging.info("Starting processing of subdirectory -- " + subdir)
    
        for i in os.listdir(data_dir + subdir):

            if i.endswith(".csv"):

                file_name = data_dir + subdir + "/" + i
                table_name = 'chad_' + subdir + "_" + i.replace(".csv","")

                logging.info("Processing file " + i + "...")

                df = pd.read_csv(file_name)
                
                # didn't realize that inf was an actual valid state for a pandas float
                # infinite ERAs are unfortunate.
                df.replace({np.inf: np.nan, -np.inf: np.nan}, inplace=True)  
                
                # with Session.begin() as session:
                df.to_sql(name=table_name
                            ,schema='stg'
                            ,con=engine
                            ,if_exists='replace'
                            ,index=False)

                logging.info(i + " successfully uploaded.")

    for i in os.listdir(tables_dir):

        ## cascading deletes and pk issues. how to handle?
        if i.endswith(".sql"):

            with open(tables_dir + i) as file:
            
                logging.info("Executing script " + i + "...")

                query = text(file.read())
                conn.execute(query)

                logging.info(i + " successfully executed.")

    ## ETL
    with open("ETL.sql") as file:
        trans = conn.begin() ## trying a transaction to fix the problem.
        logging.info("Executing ETL...")
        query = text(file.read())

        try:
            conn.execute(query)
            logging.info("ETL successfully executed.")
            trans.commit()
        except Exception:
            trans.rollback()
            raise

        ##query2 = "select * from ref.country;"
        ##result = conn.execute(query2)
        ##rows = result.fetchall()

        ## for row in rows:
           ## print(row)