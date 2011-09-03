adl application.xml

rem 生成证书的命令：
rem adt -certificate -cn AirSign 1024-RSA AirSign.p12 PASSWORD

rem 打包的命令：
rem adt -package -storetype pkcs12 -keystore D:\Me\.ssh\AirSign.p12 matrix.air application.xml .