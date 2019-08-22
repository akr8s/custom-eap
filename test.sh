# 本脚本用于测试调试用途


cd ~/custom-eap

git pull
# 参数 DB_PASSWORD=dev 代表数据即将预设的密码.
docker build  .  -t eap72
docker rm mysql-eap -f

# 容器启动需要参数 DB_VENDOR（支持mysql | oracle）  DB_ADDR  DB_PORT  DB_USER  DB_DATABASE
docker run --name mysql-eap -p 8080:8080 -p 9990:9990 -p 8443:8443 -e DB_VENDOR=mysql -e DB_ADDR=192.168.252.1 -e DB_USER=dev -e DB_PASSWORD=<数据库密文密码>   -e DB_DATABASE=devtest -e "JDBC_PARAMS=characterEncoding=UTF-8&useSSL=false"  eap72


docker exec -it mysql-eap /bin/bash

/opt/jboss/eap/bin/jboss-cli.sh 
connect
/interface=management/:write-attribute(name=inet-address,value=0.0.0.0)
shutdown 

docker restart mysql-eap

docker exec -it mysql-eap /bin/bash
/opt/jboss/eap/bin/add-user.sh 





# 生成数据库密码字符串方法.
docker exec -it mysql-eap  java -cp /opt/jboss/eap/modules/system/layers/base/org/picketbox/main/picketbox-5.0.3.Final-redhat-3.jar:/opt/jboss/eap/modules/system/layers/base/org/jboss/logging/main/jboss-logging-3.3.2.Final-redhat-00001.jar:$CLASSPATH org.picketbox.datasource.security.SecureIdentityLoginModule <数据库明文密码>