import cx_Oracle
username=""
password=""
host=""
port=1521
instance=""
tns = cx_Oracle.makedsn(host,port,instance)
con=cx_Oracle.connect(username,password,tns, mode=cx_Oracle.SYSDBA, encoding="UTF-8" ,nencoding="UTF-8")

