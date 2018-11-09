### 环境
可部署于 Centos6+，Centos7+，Debian9，Ubuntu14+

### 功能
1. 安装shadowsocksr服务端
2. 卸载shadowsocksr服务端
3. 安装v2ray
4. 卸载v2ray
5. 设置定时重启服务器
6. 时区校正`Asia/Shanghai`

### 安装wget
```
# Centos
yum -y install wget

# Ubuntu，Debian
apt-get -y install wget
```

### 执行脚本
```
wget -N --no-check-certificate https://raw.githubusercontent.com/quniu/ssrpanel-deploy/master/deploy.sh
chmod +x deploy.sh
./deploy.sh
```

### 说明
日志目录`/root/`

脚本目录`/root/`下面

SSR安装目录`/usr/local/shadowsocksr`

ssrpanel-v2ray安装目录`/usr/local/ssrpanel-v2ray`

v2ray安装目录`/usr/local/v2ray-linux-64`


### 查看shadowsocksr服务

默认安装成功之后会自动启动服务

其他服务命令

SSR
```
service shadowsocksr status
service shadowsocksr stop
service shadowsocksr start
```

v2ray
```
service v2ray status
service v2ray stop
service v2ray start
```


### 注意
安装过程会要求填写或者确认某些数据，请认真看清楚！！！！！

一下是数据库默认信息

数据库ip，默认`127.0.0.1`

数据库端口，默认`3306`

数据库名，默认`ssrpanel`

数据库用户名，默认`ssrpanel`

数据库密码，默认`password`

额外ID，既`alter-id` ，默认`16`

端口号，既`v2ray_vmess_port` ，默认`52099`

v2ray加密方式，可以多个选择，默认`auto`


### 建议

先创建节点获取到ID再去部署SSR和v2ray服务，原因如下

1. SSR创建节点时需要用到node ID，这个node ID是在后台节点列表里ID选项对应的ID值
2. v2ray创建节点时需要用到node ID 、端口号、额外ID这些信息


仅供个人参考学习，请勿用于商业活动
