#!/bin/bash

red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'

[[ $(id -u) != 0 ]] && echo -e " \n哎呀……请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}\n" && exit 1

cmd="apt-get"

sys_bit=$(uname -m)

# 笨笨的检测方法
if [[ -f /usr/bin/apt-get || -f /usr/bin/yum ]] && [[ -f /bin/systemctl ]]; then

	if [[ -f /usr/bin/yum ]]; then

		cmd="yum"

	fi

else

	echo -e " 
    哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}
    " && exit 1

fi

if [[ $sys_bit == "i386" || $sys_bit == "i686" ]]; then
	caddy_download_link="https://caddyserver.com/download/linux/386?license=personal"
elif [[ $sys_bit == "x86_64" ]]; then
	caddy_download_link="https://caddyserver.com/download/linux/amd64?license=personal"
else
	echo -e " 
    哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}
    " && exit 1
fi

ask() {

	while :; do
		echo
		echo -e "请输入一个 $magenta正确的域名$none，一定一定一定要正确，不！能！出！错！"
		read -p "(例如：233blog.com): " domain
		[ -z "$domain" ] && error && continue
		echo
		echo
		echo -e "$yellow 你的域名 = $cyan$domain$none"
		echo "----------------------------------------------------------------"
		break
	done

	get_ip

	echo
	echo -e "$yellow 请将 $magenta$domain$none $yellow解析到: $cyan$ip$none"
	echo
	echo -e "$yellow 请将 $magenta$domain$none $yellow解析到: $cyan$ip$none"
	echo
	echo -e "$yellow 请将 $magenta$domain$none $yellow解析到: $cyan$ip$none"
	echo
	echo " 重要的事情要说三次....(^_^)"
	echo "----------------------------------------------------------------"
	echo

	while :; do

		read -p "$(echo -e "(是否已经正确解析: [${magenta}Y$none]):") " record
		if [[ -z "$record" ]]; then
			error
		else
			if [[ "$record" == [Yy] ]]; then
				echo
				echo
				echo -e "$yellow 域名解析 = ${cyan}OK $none"
				echo "----------------------------------------------------------------"
				echo
				break
			else
				error
			fi
		fi

	done

	while :; do
		read -p "$(echo -e "请输入登录用户名...(默认用户名: ${magenta}233blog$none)"): " username
		[ -z "$username" ] && username="233blog"
		echo
		echo
		echo -e "$yellow 用户名 = $cyan$username$none"
		echo "----------------------------------------------------------------"
		echo
		break

	done

	while :; do
		read -p "$(echo -e "请输入用户密码...(默认密码: ${magenta}233blog.com$none)"): " userpass
		[ -z "$userpass" ] && userpass="233blog.com"
		echo
		echo
		echo -e "$yellow 用户密码 = $cyan$userpass$none"
		echo "----------------------------------------------------------------"
		echo
		break

	done

}
# plugins_ask() {
# 	echo
# 	while :; do
# 		echo -e "是否 添加 Caddy 插件 [${magenta}Y/N$none]"
# 		read -p "$(echo -e "(默认: [${cyan}N$none]):")" plugins_add
# 		[[ -z $plugins_add ]] && plugins_add="n"

# 		case $plugins_add in
# 		Y | y)
# 			plugins_config
# 			break
# 			;;
# 		N | n)
# 			echo
# 			echo
# 			echo -e "$yellow 添加 Caddy 插件 = $cyan不想添加$none"
# 			echo "----------------------------------------------------------------"
# 			echo
# 			break
# 			;;
# 		*)
# 			error
# 			;;
# 		esac
# 	done
# }
# plugins_config(){

# }
install_info() {
	clear
	echo
	echo " ....准备安装了咯..看看有毛有配置正确了..."
	echo
	echo "---------- 配置信息 -------------"
	echo
	echo -e "$yellow 你的域名 = $cyan$domain$none"
	echo
	echo -e "$yellow 域名解析 = ${cyan}OK${none}"
	echo
	echo -e "$yellow 用户名 = ${cyan}$username$none"
	echo
	echo -e "$yellow 密码 = ${cyan}$userpass$none"
	echo
	pause
}
domain_check() {
	test_domain=$(ping $domain -c 1 | grep -oE -m1 "([0-9]{1,3}\.){3}[0-9]{1,3}")
	if [[ $test_domain != $ip ]]; then
		echo -e "
		$red 检测域名解析错误....$none
		
		你的域名: $yellow$domain$none 未解析到: $cyan$ip$none

		备注...如果你的域名是使用 Cloudflare 解析的话..在 Status 那里点一下那图标..让它变灰
		" && exit 1
	fi
}
install_caddy() {
	local caddy_tmp="/tmp/install_caddy/"
	local caddy_tmp_file="/tmp/install_caddy/caddy.tar.gz"
	[[ -d $caddy_tmp ]] && rm -rf $caddy_tmp
	[[ -f $caddy_tmp_file ]] && rm -rf $caddy_tmp_file
	mkdir -p $caddy_tmp
	if [[ ! $(command -v wget) ]]; then
		$cmd update -y
		$cmd install wget -y
	fi
	if ! wget --no-check-certificate -O "$caddy_tmp_file" $caddy_download_link; then
		echo -e "
        $red 下载 Caddy 失败啦..可能是你的小鸡鸡的网络太辣鸡了...重新安装也许能解决$none
        " && exit 1
	fi

	tar zxf $caddy_tmp_file -C $caddy_tmp
	cp -f ${caddy_tmp}caddy /usr/local/bin/

	if [[ ! -f /usr/local/bin/caddy ]]; then
		echo -e "
        $red 哎呀...安装 Caddy 失败咯....$none
        " && exit 1
	fi

	cp ${caddy_tmp}init/linux-systemd/caddy.service /lib/systemd/system/
	sed -i "s/www-data/root/g" /lib/systemd/system/caddy.service
	systemctl enable caddy
	mkdir -p /etc/ssl/caddy
	mkdir -p /etc/caddy
	rm -rf $caddy_tmp $caddy_tmp_file
}
open_port() {
	if [[ $cmd == "apt-get" ]]; then
		iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
		iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
	else
		firewall-cmd --permanent --zone=public --add-port=80/tcp
		firewall-cmd --permanent --zone=public --add-port=443/udp
		firewall-cmd --reload
	fi
}
del_port() {
	if [[ $cmd == "apt-get" ]]; then
		iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
		iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
	else
		firewall-cmd --permanent --zone=public --remove-port=80/tcp
		firewall-cmd --permanent --zone=public --remove-port=443/udp
	fi
}
config_caddy() {
	email=$(shuf -i1-10000000000 -n1)
	cat >/etc/caddy/Caddyfile <<-EOF
$domain {
    gzip
    basicauth / $username $userpass
    header / Strict-Transport-Security "max-age=31536000;"
    tls ${email}@gmail.com
    proxy / https://www.google.com.hk
}
	EOF
	open_port
	systemctl restart caddy
}
show_config_info() {
	clear
	echo
	echo "---------- 安装完成 -------------"
	echo
	echo -e "$yellow 你的域名 = ${cyan}https://$domain$none"
	echo
	echo -e "$yellow 用户名 = ${cyan}$username$none"
	echo
	echo -e "$yellow 密码 = ${cyan}$userpass$none"
	echo
	echo " 帮助或反馈: https://233blog.com/post/21/"
	echo
}
uninstall() {
	if [[ -f /usr/local/bin/caddy && -f /etc/caddy/Caddyfile ]] && [[ -f /lib/systemd/system/caddy.service ]]; then
		uninstall_caddy
	else
		echo -e "
		$red 大胸弟...你貌似毛有安装 Caddy ....卸载个鸡鸡哦...$none

		备注...仅支持卸载使用我(233blog.com)提供的 Caddy 一键反代谷歌安装脚本
		" && exit 1
	fi
}
uninstall_caddy() {
	caddy_pid=$(pgrep "caddy")
	while :; do
		echo
		read -p "是否卸载[Y/N]:" uninstall_caddy_ask
		if [ -z $uninstall_caddy_ask ]; then
			error
		else
			if [[ $uninstall_caddy_ask == [Yy] ]]; then
				if [[ $caddy_pid ]]; then
					systemctl stop caddy
				fi
				systemctl disable caddy
				rm -rf /lib/systemd/system/caddy.service
				rm -rf /usr/local/bin/caddy /etc/caddy
				rm -rf /etc/ssl/caddy
				del_port
				echo
				echo -e "$green 卸载完成啦.... $none"
				echo
				break
			elif [[ $uninstall_caddy_ask == [Nn] ]]; then
				echo
				echo -e "$red....已取消卸载....$none"
				echo
				break
			else
				error
			fi
		fi

	done
}
error() {

	echo -e "\n$red 输入错误！$none\n"

}
pause() {

	read -rsp "$(echo -e "按$green Enter 回车键 $none继续....或按$red Ctrl + C $none取消.")" -d $'\n'

}
get_ip() {
	ip=$(curl -s ipinfo.io/ip)
}
try_enable_bbr() {
	if [[ $(uname -r | cut -b 1) -eq 4 ]]; then
		case $(uname -r | cut -b 3-4) in
		9. | [1-9][0-9])
			sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
			sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
			echo "net.ipv4.tcp_congestion_control = bbr" >>/etc/sysctl.conf
			echo "net.core.default_qdisc = fq" >>/etc/sysctl.conf
			sysctl -p >/dev/null 2>&1
			;;
		esac
	fi
}
only_install_caddy() {
	install_caddy
	open_port
	echo "#https://caddyserver.com/docs" >/etc/caddy/Caddyfile
	clear
	echo
	echo "---------- 安装完成 -------------"
	echo
	echo -e "$yellow Caddy 已安装完成...但还没有启动$none"
	echo
	echo -e "$yellow 请修改${cyan} /etc/caddy/Caddyfile $yellow文件$none"
	echo
	echo -e "$yellow 然后使用${cyan} systemctl start caddy $yellow启动 Caddy$none"
	echo
	echo -e "$yellow Caddy 帮助文档: ${cyan}https://caddyserver.com/docs$none"
	echo
}
install() {
	ask
	install_info
	domain_check
	install_caddy
	config_caddy
	show_config_info
}
try_enable_bbr
clear
while :; do
	echo
	echo "........... Caddy 一键反代谷歌安装脚本 by 233blog.com .........."
	echo
	echo "帮助说明: https://233blog.com/post/13/"
	echo
	echo " 1. 安装"
	echo
	echo " 2. 仅安装 Caddy..不配置反代"
	echo
	echo " 3. 卸载"
	echo
	read -p "请选择[1-3]:" choose
	case $choose in
	1)
		install
		break
		;;
	2)
		only_install_caddy
		break
		;;
	3)
		uninstall
		break
		;;
	*)
		error
		;;
	esac
done
