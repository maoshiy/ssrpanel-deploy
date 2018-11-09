#!/usr/bin/env bash

#
# System Required:  CentOS 6,7, Debian, Ubuntu
# Description: One click ShadowsocksR Server
#
# Thanks: @teddysun <https://github.com/teddysun>
# Reference URL:
# https://github.com/ssrpanel/shadowsocksr
# Author: QuNiu
#

# PATH
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# libsodium
libsodium_file="libsodium-1.0.16"
libsodium_url="https://github.com/jedisct1/libsodium/releases/download/1.0.16/libsodium-1.0.16.tar.gz"

# shadowsocksr
shadowsocksr_name="shadowsocksr"
shadowsocksr_file="shadowsocksr"
shadowsocksr_url="https://github.com/quniu/${shadowsocksr_file}.git"
shadowsocksr_service_yum="https://raw.githubusercontent.com/quniu/ssrpanel-deploy/master/service/${shadowsocksr_name}"
shadowsocksr_service_apt="https://raw.githubusercontent.com/quniu/ssrpanel-deploy/master/service/${shadowsocksr_name}-debian"

# v2ray
ssrpanel_v2ray_name="ssrpanel-v2ray"
v2ray_core_name="v2ray-linux-64"
v2ray_init_name="v2ray"
v2ray_service_yum="https://raw.githubusercontent.com/quniu/ssrpanel-deploy/master/service/${v2ray_init_name}"
v2ray_service_apt="https://raw.githubusercontent.com/quniu/ssrpanel-deploy/master/service/${v2ray_init_name}-debian"


# CyMySQL
cymysql_file="CyMySQL"
cymysql_url="https://github.com/nakagami/CyMySQL.git"

# Current folder
cur_dir=`pwd`

# Stream Ciphers
ciphers=(
none
aes-256-cfb
aes-192-cfb
aes-128-cfb
aes-256-cfb8
aes-192-cfb8
aes-128-cfb8
aes-256-ctr
aes-192-ctr
aes-128-ctr
chacha20-ietf
chacha20
salsa20
xchacha20
xsalsa20
rc4-md5
)
# Reference URL:
# https://github.com/shadowsocksr-rm/shadowsocks-rss/blob/master/ssr.md
# https://github.com/shadowsocksrr/shadowsocksr/commit/a3cf0254508992b7126ab1151df0c2f10bf82680

# Protocol
protocols=(
origin
auth_chain_a
auth_chain_b
auth_chain_c
auth_chain_d
auth_chain_e
auth_chain_f
auth_sha1_v4
auth_sha1_v4_compatible
auth_aes128_md5
auth_aes128_sha1
verify_deflate
)

# obfs
obfs=(
plain
http_simple
http_simple_compatible
http_post
http_post_compatible
tls1.2_ticket_auth
tls1.2_ticket_auth_compatible
tls1.2_ticket_fastauth
tls1.2_ticket_fastauth_compatible
)

# interfaces
interfaces=(
ssrpanel
mudbjson
sspanelv2
sspanelv3
sspanelv3ssr
glzjinmod
legendsockssr
)

# v2ray ciphers
v2ray_ciphers=(
auto
none
aes-128-gcm
chacha20-poly1305
)

# Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Make sure only root can run our script
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1

# Disable selinux
disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

# Check system
check_sys(){
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /etc/issue; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /etc/issue; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /proc/version; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /proc/version; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /proc/version; then
        release="centos"
        systemPackage="yum"
    fi

    if [[ "${checkType}" == "sysRelease" ]]; then
        if [ "${value}" == "${release}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ "${checkType}" == "packageManager" ]]; then
        if [ "${value}" == "${systemPackage}" ]; then
            return 0
        else
            return 1
        fi
    fi
}

# Get version
getversion(){
    if [[ -s /etc/redhat-release ]]; then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}

# CentOS version
centosversion(){
    if check_sys sysRelease centos; then
        local code=$1
        local version="$(getversion)"
        local main_ver=${version%%.*}
        if [ "$main_ver" == "$code" ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Get public IP address
get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    [ ! -z ${IP} ] && echo ${IP} || echo
}

# Modify time zone
modify_time(){
    # set time zone
    if check_sys packageManager yum; then
       ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    elif check_sys packageManager apt; then
       ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    fi
    # status info
    if [ $? -eq 0 ]; then
        echo -e "[${green}Info${plain}] Modify the time zone success!"
    else
        echo -e "[${yellow}Warning${plain}] Modify the time zone failure!"
    fi
}

get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}

# Pre-installation settings
install_prepare(){
    if check_sys packageManager yum || check_sys packageManager apt; then
        # Not support CentOS 5
        if centosversion 5; then
            echo -e "$[{red}Error${plain}] Not supported CentOS 5, please change to CentOS 6+/Debian 7+/Ubuntu 12+ and try again!"
            exit 1
        fi
    else
        echo -e "[${red}Error${plain}] Your OS is not supported. please change OS to CentOS/Debian/Ubuntu and try again!"
        exit 1
    fi
    # Set ShadowsocksR config password
    echo "Please enter password for ShadowsocksR:"
    read -p "(Default password: abc123456):" shadowsocksrpwd
    [ -z "${shadowsocksrpwd}" ] && shadowsocksrpwd="abc123456"
    echo
    echo "---------------------------"
    echo "password = ${shadowsocksrpwd}"
    echo "---------------------------"
    echo
    # Set ShadowsocksR config port
    while true
    do
    echo -e "Please enter a port for ShadowsocksR [1-65535]:"
    read -p "(Default port: 8989):" shadowsocksrport
    [ -z "${shadowsocksrport}" ] && shadowsocksrport="8989"
    expr ${shadowsocksrport} + 1 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ ${shadowsocksrport} -ge 1 ] && [ ${shadowsocksrport} -le 65535 ] && [ ${shadowsocksrport:0:1} != 0 ]; then
            echo
            echo "---------------------------"
            echo "port = ${shadowsocksrport}"
            echo "---------------------------"
            echo
            break
        fi
    fi
    echo -e "[${red}Error${plain}] Please enter a correct number [1-65535]"
    done

    # Set shadowsocksR config stream ciphers
    while true
    do
    echo -e "Please select stream cipher for ShadowsocksR:"
    for ((i=1;i<=${#ciphers[@]};i++ )); do
        hint="${ciphers[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "Which cipher you'd select(Default: ${ciphers[1]}):" pick
    [ -z "$pick" ] && pick=2
    expr ${pick} + 1 &>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "[${red}Error${plain}] Please enter a number"
        continue
    fi
    if [[ "$pick" -lt 1 || "$pick" -gt ${#ciphers[@]} ]]; then
        echo -e "[${red}Error${plain}] Please enter a number between 1 and ${#ciphers[@]}"
        continue
    fi
    shadowsocksrcipher=${ciphers[$pick-1]}
    echo
    echo "---------------------------"
    echo "cipher = ${shadowsocksrcipher}"
    echo "---------------------------"
    echo
    break
    done

    # Set shadowsocksR config protocol
    while true
    do
    echo -e "Please select protocol for ShadowsocksR:"
    for ((i=1;i<=${#protocols[@]};i++ )); do
        hint="${protocols[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "Which protocol you'd select(Default: ${protocols[8]}):" protocol
    [ -z "$protocol" ] && protocol=9
    expr ${protocol} + 1 &>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "[${red}Error${plain}] Input error, please input a number"
        continue
    fi
    if [[ "$protocol" -lt 1 || "$protocol" -gt ${#protocols[@]} ]]; then
        echo -e "[${red}Error${plain}] Input error, please input a number between 1 and ${#protocols[@]}"
        continue
    fi
    shadowsocksrprotocol=${protocols[$protocol-1]}
    echo
    echo "---------------------------"
    echo "protocol = ${shadowsocksrprotocol}"
    echo "---------------------------"
    echo
    break
    done

    # Set shadowsocksR config obfs
    while true
    do
    echo -e "Please select obfs for ShadowsocksR:"
    for ((i=1;i<=${#obfs[@]};i++ )); do
        hint="${obfs[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "Which obfs you'd select(Default: ${obfs[6]}):" r_obfs
    [ -z "$r_obfs" ] && r_obfs=7
    expr ${r_obfs} + 1 &>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "[${red}Error${plain}] Input error, please input a number"
        continue
    fi
    if [[ "$r_obfs" -lt 1 || "$r_obfs" -gt ${#obfs[@]} ]]; then
        echo -e "[${red}Error${plain}] Input error, please input a number between 1 and ${#obfs[@]}"
        continue
    fi
    shadowsocksrobfs=${obfs[$r_obfs-1]}
    echo
    echo "---------------------------"
    echo "obfs = ${shadowsocksrobfs}"
    echo "---------------------------"
    echo
    break
    done
}

# Download files
download_files(){
    # Clean install package
    install_cleanup

    # Download libsodium
    if ! wget --no-check-certificate -O ${libsodium_file}.tar.gz ${libsodium_url}; then
        echo -e "[${red}Error${plain}] Failed to download ${libsodium_file}.tar.gz!"
        exit 1
    fi

    # Download cymysql
    if ! git clone ${cymysql_url}; then
        echo -e "[${red}Error${plain}] Failed to download cymysql file!"
        exit 1
    fi

    # Download ShadowsocksR
    if ! git clone ${shadowsocksr_url}; then
        echo -e "[${red}Error${plain}] Failed to download ShadowsocksR file!"
        exit 1
    fi

    # Download ShadowsocksR service script
    if check_sys packageManager yum; then
        if ! wget --no-check-certificate ${shadowsocksr_service_yum} -O /etc/init.d/${shadowsocksr_name}; then
            echo -e "[${red}Error${plain}] Failed to download ShadowsocksR chkconfig file!"
            exit 1
        fi
    elif check_sys packageManager apt; then
        if ! wget --no-check-certificate ${shadowsocksr_service_apt} -O /etc/init.d/${shadowsocksr_name}; then
            echo -e "[${red}Error${plain}] Failed to download ShadowsocksR chkconfig file!"
            exit 1
        fi
    fi
}

# Firewall set
firewall_set(){
    echo -e "[${green}Info${plain}] firewall set start..."
    if centosversion 6; then
        /etc/init.d/iptables status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            iptables -L -n | grep -i ${shadowsocksrport} > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${shadowsocksrport} -j ACCEPT
                iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${shadowsocksrport} -j ACCEPT
                /etc/init.d/iptables save
                /etc/init.d/iptables restart
            else
                echo -e "[${green}Info${plain}] port ${shadowsocksrport} has been set up!"
            fi
        else
            echo -e "[${yellow}Warning${plain}] iptables looks like shutdown or not installed, please manually set it if necessary!"
        fi
    elif centosversion 7; then
        systemctl status firewalld > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            firewall-cmd --permanent --zone=public --add-port=${shadowsocksrport}/tcp
            firewall-cmd --permanent --zone=public --add-port=${shadowsocksrport}/udp
            firewall-cmd --reload
        else
            echo -e "[${yellow}Warning${plain}] firewalld looks like not running or not installed, please enable port ${shadowsocksrport} manually if necessary!"
        fi
    fi
    echo -e "[${green}Info${plain}] firewall set completed..."
}

# Set userapiconfig.py
config_userapi(){
    cat > /usr/local/${shadowsocksr_name}/userapiconfig.py<<-EOF
API_INTERFACE = '${shadowsocksrinterface}'
UPDATE_TIME = 60
SERVER_PUB_ADDR = '127.0.0.1'
MUDB_FILE = 'mudb.json'
MYSQL_CONFIG = 'usermysql.json'
MUAPI_CONFIG = 'usermuapi.json'
EOF
}

# Config user-config.json
config_userjson(){
    cat > /usr/local/${shadowsocksr_name}/user-config.json<<-EOF
{
    "server":"0.0.0.0",
    "server_ipv6": "::",
    "server_port":${shadowsocksrport},
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"${shadowsocksrpwd}",
    "method":"${shadowsocksrcipher}",
    "protocol":"${shadowsocksrprotocol}",
    "protocol_param":"",
    "obfs":"${shadowsocksrobfs}",
    "obfs_param":"",
    "speed_limit_per_con": 0,
    "speed_limit_per_user": 0,
    "additional_ports" : {},
    "additional_ports_only" : false,
    "connect_verbose_info": 1,
    "timeout":120,
    "udp_timeout": 60,
    "dns_ipv6": false,
    "redirect": ["www.amazon.com", "images-na.ssl-images-amazon.com", "m.media-amazon.com", "kdp.amazon.com", "php.net"],
    "fast_open":false
}
EOF
}

# Config usermysql.json
config_usermysql(){
    cat > /usr/local/${shadowsocksr_name}/usermysql.json<<-EOF
{
    "host": "${mysql_ip_address}",
    "port": ${mysql_ip_port},
    "user": "${mysql_user_name}",
    "password": "${mysql_db_password}",
    "db": "${mysql_db_name}",
    "node_id": ${mysql_nodeid},
    "transfer_mul": ${mysql_ratio},
    "ssl_enable": 0,
    "ssl_ca": "",
    "ssl_cert": "",
    "ssl_key": ""
}
EOF
}

# Install cymysql
install_cymysql(){
    cd ${cur_dir}
    if [ ! -d "/usr/local/${shadowsocksr_name}/cymysql" ]; then
        git clone ${cymysql_url}
        mv ${cymysql_file}/cymysql /usr/local/${shadowsocksr_name}
        echo
        echo -e "cymysql install completed!"
        echo
    else
        echo "cymysql install failed!"
        install_cleanup
        exit 1
    fi
}

# Deploy config
deploy_config(){
    while true
    do
    # Set api_interface.py
    echo -e "Please select interface for ShadowsocksR:"
    for ((i=1;i<=${#interfaces[@]};i++ )); do
        hint="${interfaces[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "Which interface you'd select(Default: ${interfaces[0]}):" interface
    [ -z "$interface" ] && interface=1
    expr ${interface} + 1 &>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "[${red}Error${plain}] Input error, please input a number"
        continue
    fi
    if [[ "$interface" -lt 1 || "$interface" -gt ${#interfaces[@]} ]]; then
        echo -e "[${red}Error${plain}] Input error, please input a number between 1 and ${#interfaces[@]}"
        continue
    fi
    shadowsocksrinterface=${interfaces[$interface-1]}
    echo
    echo "---------------------------"
    echo "api_interface = ${shadowsocksrinterface}"
    echo "---------------------------"
    echo
    break
    done

    # Set usermysql.json
    while true
    do
    #ip
    echo -e "Please enter the mysql ip address:"
    read -p "(Default address: 127.0.0.1):" mysql_ip_address
    [ -z "${mysql_ip_address}" ] && mysql_ip_address="127.0.0.1"
    expr ${mysql_ip_address} + 1 &>/dev/null
    #port
    echo -e "Please enter the mysql port:"
    read -p "(Default port: 3306):" mysql_ip_port
    [ -z "${mysql_ip_port}" ] && mysql_ip_port="3306"
    expr ${mysql_ip_port} + 1 &>/dev/null
    #db_name
    echo -e "Please enter the mysql database name:"
    read -p "(Default name: ssrpanel):" mysql_db_name
    [ -z "${mysql_db_name}" ] && mysql_db_name="ssrpanel"
    expr ${mysql_db_name} + 1 &>/dev/null
    #user_name
    echo -e "Please enter the mysql user_name:"
    read -p "(Default user: ssrpanel):" mysql_user_name
    [ -z "${mysql_user_name}" ] && mysql_user_name="ssrpanel"
    expr ${mysql_user_name} + 1 &>/dev/null
    #db_password
    echo -e "Please enter the mysql database password:"
    read -p "(Default password: password):" mysql_db_password
    [ -z "${mysql_db_password}" ] && mysql_db_password="password"
    expr ${mysql_db_password} + 1 &>/dev/null
    #nodeid
    echo -e "Please enter the node ID:"
    read -p "(Default ID: 1):" mysql_nodeid
    [ -z "${mysql_nodeid}" ] && mysql_nodeid="1"
    expr ${mysql_nodeid} + 1 &>/dev/null
    #ratio
    echo -e "Please enter the ratio of this node:"
    read -p "(Default ratio: 1.0):" mysql_ratio
    [ -z "${mysql_ratio}" ] && mysql_ratio="1.0"
    expr ${mysql_ratio} + 1 &>/dev/null
    echo
    echo -e "-----------------------------------------------------"
    echo -e "The usermysql.json Configuration has been completed! "
    echo -e "-----------------------------------------------------"
    echo -e "Your MySQL IP       : ${mysql_ip_address}            "
    echo -e "Your MySQL Port     : ${mysql_ip_port}               "
    echo -e "Your MySQL User     : ${mysql_user_name}             "
    echo -e "Your MySQL Password : ${mysql_db_password}           "
    echo -e "Your MySQL DBname   : ${mysql_db_name}               "
    echo -e "Your Node ID        : ${mysql_nodeid}                "
    echo -e "Your Transfer_mul   : ${mysql_ratio}                 "
    echo -e "-----------------------------------------------------"
    break
    done

    echo "Press any key to start install ShadowsocksR or Press Ctrl+C to cancel. Please continue!"
    char=`get_char`
    # Install necessary dependencies
    if check_sys packageManager yum; then
        yum install -y python python-devel python-setuptools openssl openssl-devel curl unzip gcc automake autoconf make libtool wget git
    elif check_sys packageManager apt; then
        apt-get -y update 
        apt-get -y install python python-dev python-setuptools openssl libssl-dev curl unzip gcc automake autoconf make libtool wget git
    fi
    cd ${cur_dir}
}

# Deploy ShadowsocksR
deploy_shadowsocksr(){
    cd ${cur_dir}
    mv ${shadowsocksr_file} /usr/local/${shadowsocksr_name}
    config_userapi
    config_userjson
    config_usermysql
    cd ${cur_dir}
}

# Install libsodium
install_libsodium(){
    if [ ! -f /usr/lib/libsodium.a ]; then
        cd ${cur_dir}
        tar zxf ${libsodium_file}.tar.gz
        cd ${libsodium_file}
        ./configure --prefix=/usr && make && make install
        if [ $? -ne 0 ]; then
            echo -e "[${red}Error${plain}] libsodium install failed!"
            install_cleanup
            exit 1
        fi
    fi

    ldconfig
}

# Starts shadowsocksr service
start_service(){
    if [ -f /usr/local/${shadowsocksr_name}/server.py ]; then
        if [ $? -eq 0 ]; then
            chmod +x /etc/init.d/${shadowsocksr_name}
            if check_sys packageManager yum; then
                chkconfig --add ${shadowsocksr_name}
                chkconfig ${shadowsocksr_name} on
            elif check_sys packageManager apt; then
                cd /etc/init.d
                update-rc.d -f ${shadowsocksr_name} defaults 90
            fi

            /etc/init.d/${shadowsocksr_name} start
            if [ $? -eq 0 ]; then
                echo -e "[${green}Info${plain}] ShadowsocksR start success!"
            else
                echo -e "[${yellow}Warning${plain}] ShadowsocksR start failure!"
            fi
            
            echo
            echo -e "-------------------------------------------------"
            echo -e "Congratulations, ShadowsocksR deploy completed!"
            echo -e "-------------------------------------------------"        
            echo -e "               Config  Info                      "
            echo -e "Your Server IP        : $(get_ip)                "
            echo -e "Your Server Port      : ${shadowsocksrport}      "
            echo -e "Your Password         : ${shadowsocksrpwd}       "
            echo -e "Your Encryption Method: ${shadowsocksrcipher}    "
            echo -e "Your Protocol         : ${shadowsocksrprotocol}  "
            echo -e "Your Obfs             : ${shadowsocksrobfs}      "
            echo -e "Your Connect Info     : 1                        "
            echo -e "               Deploy  Info                      "
            echo -e "Your Api Interface    : ${shadowsocksrinterface} "
            echo -e "Your MySQL IP         : ${mysql_ip_address}      "
            echo -e "Your MySQL Port       : ${mysql_ip_port}         " 
            echo -e "Your MySQL User       : ${mysql_user_name}       "
            echo -e "Your MySQL Password   : ${mysql_db_password}     "
            echo -e "Your MySQL DBname     : ${mysql_db_name}         "
            echo -e "Your Node ID          : ${mysql_nodeid}          "
            echo -e "Your Transfer_mul     : ${mysql_ratio}           "
            echo -e "-------------------------------------------------"         
            echo -e "                Enjoy it!                        "
            echo -e "-------------------------------------------------" 
        else
            echo
            echo -e "[${red}Error${plain}] Could not find server.py file, failed to start service!"
            exit 1
        fi

    else
        echo
        echo -e "[${red}Error${plain}] ShadowsocksR install failed!"
        exit 1
    fi
}

# Clean install
install_cleanup(){
    cd ${cur_dir}
    rm -rf ${libsodium_file}.tar.gz
    rm -rf ${libsodium_file}
    rm -rf ${shadowsocksr_file}
    rm -rf ${cymysql_file}
}


# Install ShadowsocksR
install_shadowsocksr(){
    if [ -d "/usr/local/${shadowsocksr_name}" ]; then
        printf "ShadowsocksR has been installed, Do you want to uninstall it? (y/n)"
        printf "\n"
        read -p "(Default: y):" install_answer
        [ -z ${install_answer} ] && install_answer="y"
        if [ "${install_answer}" == "y" ] || [ "${install_answer}" == "Y" ]; then
            cd ${cur_dir}
            uninstall_shadowsocksr
        else
            echo
            echo "uninstall cancelled, nothing to do..."
            echo
        fi
    else
        modify_time
        disable_selinux
        install_prepare
        deploy_config
        download_files
        install_libsodium
        deploy_shadowsocksr
        install_cymysql
        if check_sys packageManager yum; then
            firewall_set
        fi
        start_service
        install_cleanup
        exit 0
    fi
}

# Uninstall ShadowsocksR
uninstall_shadowsocksr(){
    printf "Are you sure uninstall ShadowsocksR? (y/n)"
    printf "\n"
    read -p "(Default: n):" answer
    [ -z ${answer} ] && answer="n"
    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
        if [ -d "/usr/local/${shadowsocksr_name}" ]; then
            /etc/init.d/${shadowsocksr_name} status > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                /etc/init.d/${shadowsocksr_name} stop
            fi
            if check_sys packageManager yum; then
                chkconfig --del ${shadowsocksr_name}
            elif check_sys packageManager apt; then
                update-rc.d -f ${shadowsocksr_name} remove
            fi
            install_cleanup

            rm -f /etc/init.d/${shadowsocksr_name}
            rm -f ./${shadowsocksr_name}.log
            rm -rf /usr/local/${shadowsocksr_name}
            echo "ShadowsocksR uninstall success!"
        else
            echo
            echo "Your ShadowsocksR is not installed!"
            echo
        fi
    else
        echo
        echo "uninstall cancelled, nothing to do..."
        echo
    fi
}

# Auto Reboot System
auto_reboot_system(){
    cd ${cur_dir}

    # Modify time zone
    modify_time

    #hour
    echo -e "Please enter the hour now(0-23):"
    read -p "(Default hour: 5):" auto_hour
    [ -z "${auto_hour}" ] && auto_hour="5"
    expr ${auto_hour} + 1 &>/dev/null

    #minute
    echo -e "Please enter the minute now(0-59):"
    read -p "(Default hour: 30):" auto_minute
    [ -z "${auto_minute}" ] && auto_minute="30"
    expr ${auto_minute} + 1 &>/dev/null

    echo -e "[${green}Info${plain}] The time has been set, then install crontab!"

    # Install crontabs
    if check_sys packageManager yum; then
        yum install -y vixie-cron cronie
    elif check_sys packageManager apt; then
        apt-get -y update 
        apt-get -y install cron
    fi

    echo "$auto_minute $auto_hour * * * root /sbin/reboot" >> /etc/crontab

    # start crontabs
    if check_sys packageManager yum; then
        chkconfig crond on
        service crond restart
    elif check_sys packageManager apt; then
        /etc/init.d/cron restart
    fi

    if [ $? -eq 0 ]; then
        echo -e "[${green}Info${plain}] crontab start success!"
    else
        echo -e "[${yellow}Warning${plain}] crontab start failed!"
        exit 1
    fi

    echo -e "[${green}Info${plain}] Has been installed successfully!"
    echo -e "-----------------------------------------------------"
    echo -e "The time for automatic restart has been set! "
    echo -e "-----------------------------------------------------"
    echo -e "hour       : ${auto_hour}                   "
    echo -e "minute     : ${auto_minute}                 "
    echo -e "Restart the system at ${auto_hour}:${auto_minute} every day"
    echo -e "-----------------------------------------------------"
}


########################################################  V2RAY START ########################################################
# ssrpanel-v2ray version
get_ssrpanel_v2ray_ver(){
    ssrpanel_v2ray_ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/aiyahacke/ssrpanel-v2ray/releases/latest | grep 'tag_name' | cut -d\" -f4)
    [ -z ${ssrpanel_v2ray_ver} ] && echo -e "[${red}Error${plain}] Get ssrpanel-v2ray latest version failed" && exit 1
}

# v2ray-core version
get_v2ray_core_ver(){
    v2ray_core_ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/v2ray/v2ray-core/releases/latest | grep 'tag_name' | cut -d\" -f4)
    [ -z ${v2ray_core_ver} ] && echo -e "[${red}Error${plain}] Get v2ray-core latest version failed" && exit 1
}

# download file
download(){
    local filename=$(basename $1)
    if [ -f ${1} ]; then
        echo "${filename} [found]"
    else
        echo "${filename} not found, download now..."
        wget --no-check-certificate -c -t3 -T60 -O ${1} ${2}
        if [ $? -ne 0 ]; then
            echo -e "[${red}Error${plain}] Download ${filename} failed."
            exit 1
        fi
    fi
}

# v2ray Pre-installation settings
v2ray_install_prepare(){
    if check_sys packageManager yum || check_sys packageManager apt; then
        # Not support CentOS 5
        if centosversion 5; then
            echo -e "$[{red}Error${plain}] Not supported CentOS 5, please change to CentOS 6+/Debian 7+/Ubuntu 12+ and try again!"
            exit 1
        fi
    else
        echo -e "[${red}Error${plain}] Your OS is not supported. please change OS to CentOS/Debian/Ubuntu and try again!"
        exit 1
    fi

    # Set v2ray.grpc port
    while true
    do
    echo -e "Please enter a port for v2ray.grpc [1-65535]:"
    read -p "(Default port: 52088):" v2ray_grpc_port
    [ -z "${v2ray_grpc_port}" ] && v2ray_grpc_port="52088"
    expr ${v2ray_grpc_port} + 1 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ ${v2ray_grpc_port} -ge 1 ] && [ ${v2ray_grpc_port} -le 65535 ] && [ ${v2ray_grpc_port:0:1} != 0 ]; then
            echo
            echo "---------------------------"
            echo "v2ray grpc port = ${v2ray_grpc_port}"
            echo "---------------------------"
            echo
            break
        fi
    fi
    echo -e "[${red}Error${plain}] Please enter a correct number [1-65535]"
    done

    # Set v2ray vmess port
    while true
    do
    echo -e "Please enter a port for v2ray vmess(v2ray port of panel) [1-65535]:"
    read -p "(Default port: 52099):" v2ray_vmess_port
    [ -z "${v2ray_vmess_port}" ] && v2ray_vmess_port="52099"
    expr ${v2ray_vmess_port} + 1 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ ${v2ray_vmess_port} -ge 1 ] && [ ${v2ray_vmess_port} -le 65535 ] && [ ${v2ray_vmess_port:0:1} != 0 ]; then
            echo
            echo "---------------------------"
            echo "v2ray vmess port = ${v2ray_vmess_port}"
            echo "---------------------------"
            echo
            break
        fi
    fi
    echo -e "[${red}Error${plain}] Please enter a correct number [1-65535]"
    done

    # Set v2ray ciphers
    while true
    do
    echo -e "Please select ciphers for v2ray:"
    for ((i=1;i<=${#v2ray_ciphers[@]};i++ )); do
        hint="${v2ray_ciphers[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "Which interface you'd select(Default: ${v2ray_ciphers[0]}):" encty
    [ -z "$encty" ] && encty=1
    expr ${encty} + 1 &>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "[${red}Error${plain}] Input error, please input a number"
        continue
    fi
    if [[ "$encty" -lt 1 || "$encty" -gt ${#v2ray_ciphers[@]} ]]; then
        echo -e "[${red}Error${plain}] Input error, please input a number between 1 and ${#v2ray_ciphers[@]}"
        continue
    fi
    v2ray_encryption=${v2ray_ciphers[$encty-1]}
    echo
    echo "---------------------------"
    echo "v2ray encryption = ${v2ray_encryption}"
    echo "---------------------------"
    echo
    break
    done

    # Set DB config
    while true
    do
    #ip
    echo -e "Please enter the mysql ip address:"
    read -p "(Default address: 127.0.0.1):" v2ray_mysql_ip_address
    [ -z "${v2ray_mysql_ip_address}" ] && v2ray_mysql_ip_address="127.0.0.1"
    expr ${v2ray_mysql_ip_address} + 1 &>/dev/null
    #port
    echo -e "Please enter the mysql port:"
    read -p "(Default port: 3306):" v2ray_mysql_ip_port
    [ -z "${v2ray_mysql_ip_port}" ] && v2ray_mysql_ip_port="3306"
    expr ${v2ray_mysql_ip_port} + 1 &>/dev/null
    #db_name
    echo -e "Please enter the mysql database name:"
    read -p "(Default name: ssrpanel):" v2ray_mysql_db_name
    [ -z "${v2ray_mysql_db_name}" ] && v2ray_mysql_db_name="ssrpanel"
    expr ${v2ray_mysql_db_name} + 1 &>/dev/null
    #user_name
    echo -e "Please enter the mysql user_name:"
    read -p "(Default user: ssrpanel):" v2ray_mysql_user_name
    [ -z "${v2ray_mysql_user_name}" ] && v2ray_mysql_user_name="ssrpanel"
    expr ${v2ray_mysql_user_name} + 1 &>/dev/null
    #db_password
    echo -e "Please enter the mysql database password:"
    read -p "(Default password: password):" v2ray_mysql_db_password
    [ -z "${v2ray_mysql_db_password}" ] && v2ray_mysql_db_password="password"
    expr ${v2ray_mysql_db_password} + 1 &>/dev/null
    #alter-id
    echo -e "Please enter the alter-id ID:"
    read -p "(Default ID: 16):" v2ray_mysql_alter_id
    [ -z "${v2ray_mysql_alter_id}" ] && v2ray_mysql_alter_id="16"
    expr ${v2ray_mysql_alter_id} + 1 &>/dev/null
    #nodeid
    echo -e "Please enter the node ID:"
    read -p "(Default ID: 1):" v2ray_mysql_nodeid
    [ -z "${v2ray_mysql_nodeid}" ] && v2ray_mysql_nodeid="1"
    expr ${v2ray_mysql_nodeid} + 1 &>/dev/null
    #ratio
    echo -e "Please enter the ratio of this node:"
    read -p "(Default ratio: 1.0):" v2ray_mysql_ratio
    [ -z "${v2ray_mysql_ratio}" ] && v2ray_mysql_ratio="1.0"
    expr ${v2ray_mysql_ratio} + 1 &>/dev/null
    echo
    echo -e "-----------------------------------------------------"
    echo -e "The usermysql.json Configuration has been completed! "
    echo -e "-----------------------------------------------------"
    echo -e "Your MySQL IP       : ${v2ray_mysql_ip_address}            "
    echo -e "Your MySQL Port     : ${v2ray_mysql_ip_port}               "
    echo -e "Your MySQL DBname   : ${v2ray_mysql_db_name}               "
    echo -e "Your MySQL User     : ${v2ray_mysql_user_name}             "
    echo -e "Your MySQL Password : ${v2ray_mysql_db_password}           "
    echo -e "Your Alter ID       : ${v2ray_mysql_alter_id}              "
    echo -e "Your Node  ID       : ${v2ray_mysql_nodeid}                "
    echo -e "Your Transfer_mul   : ${v2ray_mysql_ratio}                 "
    echo -e "-----------------------------------------------------"
    break
    done

    echo "Press any key to start install v2ray or Press Ctrl+C to cancel. Please continue!"
    char=`get_char`
    # Install necessary dependencies
    if check_sys packageManager yum; then
        yum install -y python python-devel python-setuptools openssl openssl-devel wget unzip java-1.8.0-openjdk java-1.8.0-openjdk-devel
    elif check_sys packageManager apt; then
        add-apt-repository ppa:openjdk-r/ppa -y 
        apt-get -y update 
        apt-get -y install python python-dev python-setuptools openssl libssl-dev wget unzip openjdk-8-jdk
    fi
    cd ${cur_dir} 
}

# download v2ray files
v2ray_download_files(){
    cd ${cur_dir}
    if [ ! -d "/usr/local/${ssrpanel_v2ray_name}" ]; then
        get_ssrpanel_v2ray_ver
        ssrpanel_v2ray_file="ssrpanel-v2ray-$(echo ${ssrpanel_v2ray_ver} | sed -e 's/^[a-zA-Z]//g')"
        ssrpanel_v2ray_url="https://github.com/aiyahacke/ssrpanel-v2ray/releases/download/${ssrpanel_v2ray_ver}/${ssrpanel_v2ray_file}.zip"
        download "${ssrpanel_v2ray_file}.zip" "${ssrpanel_v2ray_url}"
    else
        echo -e "[${green}Info${plain}] ssrpanel-v2ray already installed."
        exit 1
    fi  

    if [ ! -d "/usr/local/${v2ray_core_name}" ]; then
        get_v2ray_core_ver
        v2ray_core_file="v2ray-linux-64"
        v2ray_core_url="https://github.com/v2ray/v2ray-core/releases/download/${v2ray_core_ver}/${v2ray_core_file}.zip"
        download "${v2ray_core_file}.zip" "${v2ray_core_url}"
    else
        echo -e "[${green}Info${plain}] v2ray-core already installed."
        exit 1
    fi 

    if check_sys packageManager yum; then
        download "/etc/init.d/${v2ray_init_name}" "${v2ray_service_yum}"
    elif check_sys packageManager apt; then
        download "/etc/init.d/${v2ray_init_name}" "${v2ray_service_apt}"
    fi
}

# ssrpanel_v2ray config
config_ssrpanel_v2ray(){
    cat > /usr/local/${ssrpanel_v2ray_name}/config.properties<<-EOF
############################## V2ray配置 ##############################

# v2ray路径
v2ray.path=/usr/local/${v2ray_core_name}

# 可执行文件名
v2ray.exec=v2ray

# GRPC设置
v2ray.grpc.address=127.0.0.1
v2ray.grpc.port=${v2ray_grpc_port}

# 协议标签
v2ray.tag=proxy

# 加密方式 可选值(aes-128-gcm, chacha20-poly1305, none, auto)
v2ray.security=${v2ray_encryption}

# 额外ID
v2ray.alter-id=${v2ray_mysql_alter_id}

# 用户等级
v2ray.level=1



############################## 节点配置 ##############################

# 节点ID
node.id=${v2ray_mysql_nodeid}

# 检查时间(秒)
node.check-rate=60

# 流量比例
node.traffic-rate=${v2ray_mysql_ratio}



############################## 数据库配置 ##############################

datasource.url=jdbc:mysql://${v2ray_mysql_ip_address}:${v2ray_mysql_ip_port}/${v2ray_mysql_db_name}?serverTimezone=GMT%2B8
datasource.username=${v2ray_mysql_user_name}
datasource.password=${v2ray_mysql_db_password}
datasource.hikari.maximum-pool-size=10
datasource.hikari.minimum-idle=3

EOF
}

# Config v2ray config.json
config_v2ray(){
    cat > /usr/local/${v2ray_core_name}/config.json<<-EOF
{
  "api": {
    "services": [
      "HandlerService",
      "StatsService"
    ],
    "tag": "api"
  },
  "stats": {},
  "inbound": {
    "port": ${v2ray_vmess_port},
    "protocol": "vmess",
    "settings": {
      "clients": []
    },
    "streamSettings": {
      "network": "tcp"
    },
    "tag": "proxy"
  },
  "inboundDetour": [
    {
      "listen": "0.0.0.0",
      "port": ${v2ray_grpc_port},
      "protocol": "dokodemo-door",
      "settings": {
        "address": "0.0.0.0"
      },
      "tag": "api"
    }
  ],
  "log": {
    "access": "./access.log",
    "error": "./error.log",
    "loglevel": "debug"
  },
  "outbound": {
    "protocol": "freedom",
    "settings": {}
  },
  "routing": {
    "settings": {
      "rules": [
        {
          "inboundTag": [
            "api"
          ],
          "outboundTag": "api",
          "type": "field"
        }
      ]
    },
    "strategy": "rules"
  },
  "policy": {
    "levels": {
      "1": {
        "statsUserUplink": true,
        "statsUserDownlink": true
      }
    }
  }
}
EOF
}

# Deploy v2ray
v2ray_deploy(){
    unzip ${ssrpanel_v2ray_file}.zip -d /usr/local/${ssrpanel_v2ray_name}
    unzip ${v2ray_core_file}.zip -d /usr/local/${v2ray_core_name}
    mv /usr/local/${ssrpanel_v2ray_name}/${ssrpanel_v2ray_file}.jar /usr/local/${ssrpanel_v2ray_name}/${ssrpanel_v2ray_name}.jar
    config_ssrpanel_v2ray
    config_v2ray
    rm -rf /usr/local/${ssrpanel_v2ray_name}/config.json
    cp -rf /usr/local/${v2ray_core_name}/config.json /usr/local/${ssrpanel_v2ray_name}
    chmod -R a+x /usr/local/${ssrpanel_v2ray_name}
    chmod -R a+x /usr/local/${v2ray_core_name}
}

# Start v2ray service
v2ray_start_service(){
    cd /usr/local/${ssrpanel_v2ray_name}
    if [ -f /usr/local/${ssrpanel_v2ray_name}/${ssrpanel_v2ray_name}.jar ]; then
        if [ $? -eq 0 ]; then
            chmod +x /etc/init.d/${v2ray_init_name}
            if check_sys packageManager yum; then
                chkconfig --add ${v2ray_init_name}
                chkconfig ${v2ray_init_name} on
            elif check_sys packageManager apt; then
                cd /etc/init.d
                update-rc.d -f ${v2ray_init_name} defaults 90
            fi

            /etc/init.d/${v2ray_init_name} start
            if [ $? -eq 0 ]; then
                echo -e "[${green}Info${plain}] v2ray start success!"
                echo
                echo -e "---------------------------------------------------"
                echo -e "Congratulations, v2ray deploy completed!"
                echo -e "---------------------------------------------------"        
                echo -e "               Config  Info                        "
                echo -e "Your Server IP        : $(get_ip)                  "
                echo -e "Your V2ray Grpc Port  : ${v2ray_grpc_port}         "
                echo -e "Your V2ray Vmess Port : ${v2ray_vmess_port}        "
                echo -e "Your Encryption Method: ${v2ray_encryption}        "
                echo -e "               Deploy  Info                        "
                echo -e "Your MySQL IP         : ${v2ray_mysql_ip_address}  "
                echo -e "Your MySQL Port       : ${v2ray_mysql_ip_port}     " 
                echo -e "Your MySQL DBname     : ${v2ray_mysql_db_name}     "
                echo -e "Your MySQL User       : ${v2ray_mysql_user_name}   "
                echo -e "Your MySQL Password   : ${v2ray_mysql_db_password} "
                echo -e "Your Alter ID         : ${v2ray_mysql_alter_id}    "
                echo -e "Your Node ID          : ${v2ray_mysql_nodeid}      "
                echo -e "Your Transfer_mul     : ${v2ray_mysql_ratio}       "
                echo -e "---------------------------------------------------"         
                echo -e "                Enjoy it!                          "
                echo -e "---------------------------------------------------" 
            else
                echo -e "[${yellow}Warning${plain}] v2ray start failure!"
            fi
            
        else
            echo
            echo -e "[${red}Error${plain}] Could not find jar file, failed to start service!"
            exit 1
        fi
    else
        echo
        echo -e "[${red}Error${plain}] Could not find jar file, failed to start service!"
        exit 1
    fi
}

# v2ray firewall
v2ray_firewall_set(){
    echo -e "[${green}Info${plain}] firewall set start..."
    if centosversion 6; then
        /etc/init.d/iptables status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            iptables -L -n | grep -i ${v2ray_grpc_port} > /dev/null 2>&1
            iptables -L -n | grep -i ${v2ray_vmess_port} > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${v2ray_grpc_port} -j ACCEPT
                iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${v2ray_grpc_port} -j ACCEPT
                iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${v2ray_vmess_port} -j ACCEPT
                iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${v2ray_vmess_port} -j ACCEPT
                /etc/init.d/iptables save
                /etc/init.d/iptables restart
            else
                echo -e "[${green}Info${plain}] port ${v2ray_grpc_port} ${v2ray_vmess_port} has been set up!"
            fi
        else
            echo -e "[${yellow}Warning${plain}] iptables looks like shutdown or not installed, please manually set it if necessary!"
        fi
    elif centosversion 7; then
        systemctl status firewalld > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            firewall-cmd --permanent --zone=public --add-port=${v2ray_grpc_port}/tcp
            firewall-cmd --permanent --zone=public --add-port=${v2ray_grpc_port}/udp
            firewall-cmd --permanent --zone=public --add-port=${v2ray_vmess_port}/tcp
            firewall-cmd --permanent --zone=public --add-port=${v2ray_vmess_port}/udp
            firewall-cmd --reload
        else
            echo -e "[${yellow}Warning${plain}] firewalld looks like not running or not installed, please enable port ${v2ray_grpc_port} ${v2ray_vmess_port} manually if necessary!"
        fi
    fi
    echo -e "[${green}Info${plain}] firewall set completed..."
}

# Install v2ray
install_v2ray(){
    if [ -d "/usr/local/${ssrpanel_v2ray_name}" ]; then
        printf "ssrpanel-v2ray has been installed, Do you want to uninstall it? (y/n)"
        printf "\n"
        read -p "(Default: y):" install_answer
        [ -z ${install_answer} ] && install_answer="y"
        if [ "${install_answer}" == "y" ] || [ "${install_answer}" == "Y" ]; then
            cd ${cur_dir}
            uninstall_v2ray
        else
            echo
            echo "uninstall cancelled, nothing to do..."
            echo
        fi
    else
        modify_time
        disable_selinux
        v2ray_install_prepare
        v2ray_download_files
        v2ray_deploy
        if check_sys packageManager yum; then
            v2ray_firewall_set
        fi
        v2ray_start_service
        v2ray_install_cleanup
        exit 0
    fi
}

# Clean v2ray install
v2ray_install_cleanup(){
    cd ${cur_dir}
    rm -rf ${ssrpanel_v2ray_file}.zip
    rm -rf ${v2ray_core_file}.zip
}

# Uninstall v2ray
uninstall_v2ray(){
    printf "Are you sure uninstall v2ray? (y/n)"
    printf "\n"
    read -p "(Default: n):" answer
    [ -z ${answer} ] && answer="n"
    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
        if [ -d "/usr/local/${ssrpanel_v2ray_name}" ]; then
            /etc/init.d/${v2ray_init_name} status > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                /etc/init.d/${v2ray_init_name} stop
            fi
            if check_sys packageManager yum; then
                chkconfig --del ${v2ray_init_name}
            elif check_sys packageManager apt; then
                update-rc.d -f ${v2ray_init_name} remove
            fi
            v2ray_install_cleanup

            rm -f /etc/init.d/${v2ray_init_name}
            rm -rf /usr/local/${ssrpanel_v2ray_name}
            rm -rf /usr/local/${v2ray_core_name}

            echo "v2ray uninstall success!"
        else
            echo
            echo "Your v2ray is not installed!"
            echo
        fi
    else
        echo
        echo "uninstall cancelled, nothing to do..."
        echo
    fi
}
########################################################  V2RAY END ########################################################

# Initialization step
commands=(
Install\ shadowsocksr
Uninstall\ shadowsocksr
Install\ v2ray
Uninstall\ v2ray
Auto\ reboot\ system
Modify\ time\ zone
)


# Choose command
choose_command(){
    clear
      
    while true
    do
    echo 
    echo -e "Welcome! Please select command to start:"
    echo -e "-------------------------------------------"
    for ((i=1;i<=${#commands[@]};i++ )); do
        hint="${commands[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    echo -e "-------------------------------------------"
    read -p "Which command you'd select(Default: ${commands[0]}):" order_num
    [ -z "$order_num" ] && order_num=1
    expr ${order_num} + 1 &>/dev/null
    if [ $? -ne 0 ]; then
        echo 
        echo -e "[${red}Error${plain}] Please enter a number"
        continue
    fi
    if [[ "$order_num" -lt 1 || "$order_num" -gt ${#commands[@]} ]]; then
        echo 
        echo -e "[${red}Error${plain}] Please enter a number between 1 and ${#commands[@]}"
        continue
    fi
    break
    done

    case $order_num in
        1)
        install_shadowsocksr
        ;;
        2)
        uninstall_shadowsocksr
        ;;
        3)
        install_v2ray
        ;;
        4)
        uninstall_v2ray
        ;;
        5)
        auto_reboot_system
        ;;
        6)
        modify_time
        ;;
        *)
        exit 1
        ;;
    esac
}
# start
cd ${cur_dir}
choose_command
