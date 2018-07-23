### 功能
1. 安装shadowsocksr服务端
2. 卸载shadowsocksr服务端
3. 设置定时重启

### 安装wget
```
# centos
yum -y install wget

# Ubuntu
apt-get -y install wget
```

### 执行脚本
```
rm -rf ./deploy.sh ./shadowsocksr.log
wget -N --no-check-certificate https://raw.githubusercontent.com/quniu/ssrpanel-deploy/master/deploy.sh
chmod +x deploy.sh
./deploy.sh 2>&1 | tee shadowsocksr.log
```

### 说明
日志在`/root/`下面

脚本在`/root/`下面

安装路径在`/usr/local/shadowsocksr`下面

### 查看shadowsocksr服务

默认安装成功之后会自动启动服务

其他服务命令
```
service shadowsocksr status
service shadowsocksr stop
service shadowsocksr start
```

### 注意
安装过程会要求填写或者确认某些数据，请认真看清楚！！！！！

一下是数据库默认信息

数据库ip，默认`127.0.0.1`

数据库端口，默认`3306`

数据库名，默认`ssrpanel`

数据库用户名，默认`ssrpanel`

数据库密码，默认`password`

### 建议

先创建节点获取到ID再去部署shadowsocksr服务，因为配置需要填的node ID，这个node ID是在后台节点列表里ID选项对应的ID值


仅供个人参考学习，请勿用于商业活动
