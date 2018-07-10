##################################################
# Anything wrong? Find me via telegram: @CN_SZTL #
##################################################

#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

function set_fonts_colors(){
# Font colors
default_fontcolor="\033[0m"
red_fontcolor="\033[31m"
green_fontcolor="\033[32m"
# Background colors
green_backgroundcolor="\033[42;37m"
# Fonts
error_font="${red_fontcolor}[Error]${default_fontcolor}"
ok_font="${green_fontcolor}[OK]${default_fontcolor}"
}

function check_os(){
	clear
	echo -e "正在检测当前是否为ROOT用户..."
	if [[ $EUID -ne 0 ]]; then
		clear
		echo -e "${error_font}当前并非ROOT用户，请先切换到ROOT用户后再使用本脚本。"
		exit 1
	else
		clear
		echo -e "${ok_font}检测到当前为Root用户。"
	fi
	clear
	echo -e "正在检测此OS是否被支持..."
	if [ ! -z "$(cat /etc/issue | grep Debian)" ];then
		OS='debian'
		clear
		echo -e "${ok_font}该脚本支持您的系统。"
	elif [ ! -z "$(cat /etc/issue | grep Ubuntu)" ];then
		OS='ubuntu'
		clear
		echo -e "${ok_font}该脚本支持您的系统。"
	else
		clear
		echo -e "${error_font}目前暂不支持您使用的操作系统，请切换至Debian/Ubuntu。"
		exit 1
	fi
}

function check_install_status(){
	install_type=$(cat /etc/v2ray/install_type.txt)
	if [[ ${install_type} = "" ]]; then
		install_status="${red_fontcolor}未安装${default_fontcolor}"
		now_tg_link="${red_fontcolor}未安装${default_fontcolor}"
	else
		install_status="${green_fontcolor}已安装${default_fontcolor}"
		now_tg_link="${green_backgroundcolor}$(cat /etc/v2ray/tg_link.txt)${default_fontcolor}"
	fi
	v2ray_config=$(cat /etc/v2ray/config.json)
	if [[ ${v2ray_config} = "" ]]; then
		v2ray_status="${red_fontcolor}未安装${default_fontcolor}"
	else
		v2ray_pid=$(ps -ef |grep "v2ray" |grep -v "grep" | grep -v ".sh"| grep -v "init.d" |grep -v "service" |awk '{print $2}')
		if [[ ${v2ray_pid} = "" ]]; then
			v2ray_status="${red_fontcolor}未运行${default_fontcolor}"
		else
			v2ray_status="${green_fontcolor}正在运行${default_fontcolor} | ${green_fontcolor}${v2ray_pid}${default_fontcolor}"
		fi
	fi
}

function echo_install_list(){
	clear
	echo -e "脚本当前安装状态：${install_status}
------------------------------------------------
	0.清除V2Ray
	1.安装HTTP-ForTG
	2.安装Socks5-ForTG
------------------------------------------------
V2Ray当前运行状态：${v2ray_status}
	3.更新脚本
	4.更新程序
	5.卸载程序

	6.启动程序
	7.关闭程序
	8.重启程序
------------------------------------------------
TG-Link：${now_tg_link}
------------------------------------------------"
	stty erase '^H' && read -p "请输入序号：" determine_type
	if [[ ${determine_type} = "" ]]; then
		clear
		echo -e "${error_font}请输入序号！"
		exit 1
	elif [[ ${determine_type} -lt 0 ]]; then
		clear
		echo -e "${error_font}请输入正确的序号！"
		exit 1
	elif [[ ${determine_type} -gt 8 ]]; then
		clear
		echo -e "${error_font}请输入正确的序号！"
		exit 1
	else
		data_processing
	fi
}

function data_processing(){
	clear
	echo -e "正在处理请求中..."
	if [[ ${determine_type} = "0" ]]; then
		uninstall_old
	elif [[ ${determine_type} = "3" ]]; then
		upgrade_shell_script
	elif [[ ${determine_type} = "4" ]]; then
		prevent_uninstall_check
		upgrade_program
		restart_service
	elif [[ ${determine_type} = "5" ]]; then
		prevent_uninstall_check
		uninstall_program
	elif [[ ${determine_type} = "6" ]]; then
		prevent_uninstall_check
		start_service
	elif [[ ${determine_type} = "7" ]]; then
		prevent_uninstall_check
		stop_service
	elif [[ ${determine_type} = "8" ]]; then
		prevent_uninstall_check
		restart_service
	else
		prevent_install_check
		os_update
		check_time
		generate_base_config
		clear
		echo -e "安装V2Ray主程序中..."
		bash <(curl https://install.direct/go.sh)
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}V2Ray安装成功。"
		else
			clear
			echo -e "${error_font}V2Ray安装失败！"
			exit 1
		fi
	fi
		if [[ ${determine_type} = "1" ]]; then
			wget -O "/etc/v2ray/config.json" "https://raw.githubusercontent.com/1715173329/v2ray-onekey/master/tg-proxy/http.json"
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}HTTP 配置文件下载成功。"
			else
				clear
				echo -e "${error_font}HTTP 配置文件下载失败！"
				clear_install
				exit 1
			fi
			input_port
			stty erase '^H' && read -p "请输入HTTP用户名(默认：username)：" install_http_username
			if [[ ${install_http_username} = "" ]]; then
				install_http_username="username"
			else
				sed -i "s/username/${install_http_username}/g" "/etc/v2ray/config.json"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}HTTP用户名配置成功。"
				else
					clear
					echo -e "${error_font}HTTP用户名配置失败！"
					clear_install
					exit 1
				fi
			fi
			stty erase '^H' && read -p "请输入HTTP密码(默认：passwd)：" install_http_password
			if [[ ${install_http_password} = "" ]]; then
				install_http_password="passwd"
			else
				sed -i "s/passwd/${install_http_password}/g" "/etc/v2ray/config.json"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}HTTP密码配置成功。"
				else
					clear
					echo -e "${error_font}HTTP密码配置失败！"
					clear_install
					exit 1
				fi
			fi
			echo "1" > /etc/v2ray/install_type.txt
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}写入安装信息成功。"
			else
				clear
				echo -e "${error_font}写入安装信息失败！"
				clear_install
				exit 1
			fi
			restart_service
			echo_v2ray_config
		elif [[ ${determine_type} = "2" ]]; then
			wget -O "/etc/v2ray/config.json" "https://raw.githubusercontent.com/1715173329/v2ray-onekey/master/tg-proxy/socks.json"
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}Socks5 配置文件下载成功。"
			else
				clear
				echo -e "${error_font}Socks5 配置文件下载失败！"
				clear_install
				exit 1
			fi
			input_port
			stty erase '^H' && read -p "请输入Socks用户名(默认：username)：" install_socks_username
			if [[ ${install_socks_username} = "" ]]; then
				install_socks_username="username"
			else
				sed -i "s/username/${install_socks_username}/g" "/etc/v2ray/config.json"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}Socks用户名配置成功。"
				else
					clear
					echo -e "${error_font}Socks用户名配置失败！"
					clear_install
					exit 1
				fi
			fi
			stty erase '^H' && read -p "请输入Socks密码(默认：passwd)：" install_socks_password
			if [[ ${install_socks_password} = "" ]]; then
				install_socks_password="passwd"
			else
				sed -i "s/passwd/${install_socks_password}/g" "/etc/v2ray/config.json"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}Socks密码配置成功。"
				else
					clear
					echo -e "${error_font}Socks密码配置失败！"
					clear_install
					exit 1
				fi
			fi
			echo "1" > /etc/v2ray/install_type.txt
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}写入安装信息成功。"
			else
				clear
				echo -e "${error_font}写入安装信息失败！"
				clear_install
				exit 1
			fi
			restart_service
			echo_v2ray_config
		fi
	echo -e "\n${ok_font}请求处理完毕。"
}

function uninstall_old(){
	clear
	echo -e "正在检查安装信息中..."
	clear
	if [[ ${v2ray_status} = "${red_fontcolor}未安装${default_fontcolor}" ]]; then
		clear
		echo -e "${error_font}您未安装V2Ray。"
	else
		service v2ray stop
		update-rc.d -f v2ray remove
		systemctl disable v2ray.service
		rm -rf /etc/init.d/v2ray
		rm -rf /lib/systemd/system/v2ray.service
		rm -rf /etc/systemd/system/v2ray.service
		rm -rf /etc/v2ray
		rm -rf /usr/bin/v2ray
		rm -rf /var/log/v2ray
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}V2Ray卸载成功。"
		else
			clear
			echo -e "${error_font}V2Ray卸载失败！"
		fi
	fi
}

function upgrade_shell_script(){
	clear
	echo -e "正在更新脚本中..."
	filepath=$(cd "$(dirname "$0")"; pwd)
	filename=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
	curl -O https://raw.githubusercontent.com/1715173329/v2ray-onekey/master/tg-proxy/v2ray-go.sh
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}脚本更新成功，脚本位置：\"${green_backgroundcolor}${filename}/v2ray-go.sh${default_fontcolor}\"，使用：\"${green_backgroundcolor}bash ${filename}/v2ray-go.sh${default_fontcolor}\"。"
	else
		clear
		echo -e "${error_font}脚本更新失败！"
		exit 1
	fi
}

function prevent_uninstall_check(){
	clear
	echo -e "正在检查安装状态中..."
	install_type=$(cat /etc/v2ray/install_type.txt)
	if [ "${install_type}" = "" ]; then
		clear
		echo -e "${error_font}您未安装本程序。"
		exit 1
	else
		echo -e "${ok_font}您已安装本程序，正在执行相关命令中..."
	fi
}

function start_service(){
	clear
	echo -e "正在启动服务中..."
	if [[ ${v2ray_pid} = "" ]]; then
		service v2ray start
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}V2Ray 启动成功。"
		else
			clear
			echo -e "${error_font}V2Ray 启动失败！"
			exit 1
		fi
	else
		clear
		echo -e "${error_font}V2Ray 正在运行。"
	fi
}

function stop_service(){
	clear
	echo -e "正在停止服务中..."
	if [[ ${v2ray_pid} -eq 0 ]]; then
		clear
		echo -e "${error_font}V2Ray 未在运行。"
	else
		service v2ray stop
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}V2Ray 停止成功。"
		else
			clear
			echo -e "${error_font}V2Ray 停止失败！"
			exit 1
		fi
	fi
}

function restart_service(){
	clear
	echo -e "正在重启服务中..."
	service v2ray restart
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}V2Ray 重启成功。"
	else
		clear
		echo -e "${error_font}V2Ray 重启失败！"
		exit 1
	fi
}

function prevent_install_check(){
	clear
	echo -e "正在检测安装状态中..."
	if [[ ${install_status} = "${green_fontcolor}已安装${default_fontcolor}" ]]; then
		echo -e "${error_font}您已经安装过了，请勿再次安装，若您需要切换至其他模式，请先卸载后再使用安装功能。"
		exit 1
	elif [[ ${v2ray_status} = "${red_fontcolor}未安装${default_fontcolor}" ]]; then
		echo -e "${ok_font}检测完毕，符合要求，正在执行命令中..."
	else
		echo -e "${error_font}您的VPS上已经安装V2Ray，请勿再次安装，若您需要使用本脚本，请先卸载后再使用安装功能。"
		exit 1
	fi
}

function uninstall_program(){
	clear
	echo -e "正在卸载中..."
	close_port
	service v2ray stop
	update-rc.d -f v2ray remove
	systemctl disable v2ray.service
	rm -rf /etc/init.d/v2ray
	rm -rf /lib/systemd/system/v2ray.service
	rm -rf /etc/systemd/system/v2ray.service
	rm -rf /etc/v2ray
	rm -rf /usr/bin/v2ray
	rm -rf /var/log/v2ray
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}V2Ray卸载成功。"
	else
		clear
		echo -e "${error_font}V2Ray卸载失败！"
		exit 1
	fi
}

function upgrade_program(){
	clear
	echo -e "正在更新程序中..."
	install_type=$(cat /etc/v2ray/install_type.txt)
	if [ "${install_type}" = "" ]; then
		bash <(curl https://install.direct/go.sh)
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}V2Ray 更新成功。"
		else
			clear
			echo -e "${error_font}V2Ray 更新失败！"
			exit 1
		fi
	fi
}

function clear_install(){
	clear
	echo -e "正在卸载中..."
	close_port
	service v2ray stop
	update-rc.d -f v2ray remove
	systemctl disable v2ray.service
	rm -rf /etc/init.d/v2ray
	rm -rf /lib/systemd/system/v2ray.service
	rm -rf /etc/systemd/system/v2ray.service
	rm -rf /etc/v2ray
	rm -rf /usr/bin/v2ray
	rm -rf /var/log/v2ray
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}V2Ray卸载成功。"
	else
		clear
		echo -e "${error_font}V2Ray卸载失败！"
		exit 1
	fi
}

function os_update(){
	clear
	echo -e "正在安装/更新系统组件中..."
	clear
	apt-get -y update
	apt-get -y upgrade
	apt-get -y install wget curl ntpdate unzip lsof cron iptables
	if [[ $? -ne 0 ]];then
		clear
		echo -e "${error_font}系统组件更新失败！"
		exit 1
	else
		clear
		echo -e "${ok_font}系统组件更新成功。"
	fi
}

function check_time(){
	clear
	echo -e "正在对时中..."
	rm -rf /etc/localtime
	cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	ntpdate time.nist.gov
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}时间同步成功。"
		echo -e "${ok_font}当前系统时间 $(date -R) （请注意时区间时间换算，换算后时间误差应为三分钟以内）"
	else
		clear
		echo -e "${error_font}时间同步失败，请检查ntpdate服务是否正常工作。"
		echo -e "${error_font}当前系统时间 $(date -R) ，如果和你的本地时间有误差，请手动调整。"
	fi 
}

function generate_base_config(){
	clear
	echo -e "正在读取VPS_IP中..."
	Address=$(curl https://ipinfo.io/ip)
	let v2_listen_port=$RANDOM+10000
	if [[ ${Address} = "" ]]; then
		clear
		echo -e "${error_font}读取VPS_IP失败！"
		exit 1
	else
		clear
		echo -e "${ok_font}您的vps_ip为：${Address}"
	fi
}

function input_port(){
	clear
	stty erase '^H' && read -p "请输入监听端口(默认监听8080端口)：" install_port
	if [[ ${install_port} = "" ]]; then
		install_port="8080"
	fi
	check_port
	sed -i "s/8080/${install_port}/g" "/etc/v2ray/config.json"
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}V2Ray端口配置成功。"
	else
		clear
		echo -e "${error_font}V2Ray端口配置失败！"
		clear_install
		exit 1
	fi
}

function check_port(){
	clear
	echo "正在检查端口占用情况："
	if [[ 0 -eq $(lsof -i:"${install_port}" | wc -l) ]];then
		clear
		echo -e "${ok_font}端口未被占用。"
		open_port
		echo "${install_port}" > /etc/v2ray/install_port.txt
	else
		clear
		echo -e "${error_font}端口被占用，请切换使用其他端口。"
		clear_install
		exit 1
	fi
}

function open_port(){
	clear
	echo -e "正在设置防火墙中..."
	iptables-save > /etc/iptables.up.rules
	echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
	chmod +x /etc/network/if-pre-up.d/iptables
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${install_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${install_port} -j ACCEPT
	iptables-save > /etc/iptables.up.rules
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}端口开放配置成功。"
	else
		clear
		echo -e "${error_font}端口开放配置失败！"
		clear_install
		exit 1
	fi
}

function close_port(){
	clear
	echo -e "正在设置防火墙中..."
	uninstall_port=$(cat /etc/v2ray/install_port.txt)
	iptables-save > /etc/iptables.up.rules
	echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
	chmod +x /etc/network/if-pre-up.d/iptables
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${uninstall_port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${uninstall_port} -j ACCEPT
	iptables-save > /etc/iptables.up.rules
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}端口关闭配置成功。"
	else
		clear
		echo -e "${error_font}端口关闭配置失败！"
	fi
}

function echo_v2ray_config(){
	if [[ ${determine_type} = "1" ]]; then
		clear
		tglink="https://t.me/http?server=${Address}&port=${install_port}&user=${install_http_username}&pass=${install_http_password}"
		echo -e "您的连接信息如下："
		echo -e "地址(Hostname)：${Address}"
		echo -e "端口(Port)：${install_port}"
		echo -e "用户名(Username)：${install_http_username}"
		echo -e "密码(Password)：${install_http_password}"
		echo -e "代理协议(Proxy Type)：http"
		echo -e "Telegram设置链接： ${green_backgroundcolor}${tglink}${default_fontcolor}"
	elif [[ ${determine_type} = "2" ]]; then
		clear
		tglink="https://t.me/socks?server=${Address}&port=${install_port}&user=${install_socks_username}&pass=${install_socks_password}"
		echo -e "您的连接信息如下："
		echo -e "地址(Hostname)：${Address}"
		echo -e "端口(Port)：${install_port}"
		echo -e "用户名(Username)：${install_socks_username}"
		echo -e "密码(Password)：${install_socks_password}"
		echo -e "代理协议(Proxy Type)：socks5"
		echo -e "Telegram设置链接： ${green_backgroundcolor}${tglink}${default_fontcolor}"
	fi
	echo -e "${tglink}" > /etc/v2ray/tg_link.txt
}

function main(){
	set_fonts_colors
	check_os
	check_install_status
	echo_install_list
}

	main