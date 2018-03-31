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
	# Check root user
	echo -e "正在检测当前是否为ROOT用户..."
	if [[ $EUID -ne 0 ]]; then
		sudo su
		check_os
		clear
		echo -e "${error_font}当前并非ROOT用户，请先切换到ROOT用户后再使用本脚本。"
		exit 1
	else
		clear
		echo -e "${ok_font}检测到当前为Root用户。"
	fi
	# Check OS type
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
		now_vmess_link="${red_fontcolor}未安装${default_fontcolor}"
	else
		install_status="${green_fontcolor}已安装${default_fontcolor}"
		now_vmess_link="${green_backgroundcolor}$(cat /etc/v2ray/vmess_link.txt)${default_fontcolor}"
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
	caddy_config=$(cat /usr/local/caddy/Caddyfile)
	if [[ ${caddy_config} = "" ]]; then
		caddy_status="${red_fontcolor}未安装${default_fontcolor}"
	else
		caddy_pid=$(ps -ef |grep "caddy" |grep -v "grep" | grep -v ".sh"| grep -v "init.d" |grep -v "service" |awk '{print $2}')
		if [[ ${caddy_pid} = "" ]]; then
			caddy_status="${red_fontcolor}未运行${default_fontcolor}"
		else
			caddy_status="${green_fontcolor}正在运行${default_fontcolor} | ${green_fontcolor}${caddy_pid}${default_fontcolor}"
		fi
	fi
}

function echo_install_list(){
	clear
	echo -e "脚本当前安装状态：${install_status}
--------------------------------------------------------------------------------------------------
安装V2ray:
	0.清除V2Ray/Caddy
	1.Socks5
	2.TCP+HTTP伪装
	3.TCP+TLS
	4.Mkcp+BT流量伪装
	5.Mkcp+Facetime视频流量伪装
	6.Mkcp+Facetime视频流量伪装+动态端口
	7.HTTP/2+TLS
	8.Websocket+TLS+网站伪装
--------------------------------------------------------------------------------------------------
V2Ray当前运行状态：${v2ray_status}
Caddy当前运行状态：${caddy_status}
	9.更新脚本
	10.更新程序
	11.卸载程序

	12.启动程序
	13.关闭程序
	14.重启程序
--------------------------------------------------------------------------------------------------
Vmess链接：${now_vmess_link}
--------------------------------------------------------------------------------------------------"
	stty erase '^H' && read -p "请输入序号：" determine_type
	if [[ ${determine_type} = "" ]]; then
		clear
		echo -e "${error_font}请输入序号！"
		exit 1
	elif [[ ${determine_type} -lt 0 ]]; then
		clear
		echo -e "${error_font}请输入正确的序号！"
		exit 1
	elif [[ ${determine_type} -gt 14 ]]; then
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
	elif [[ ${determine_type} = "9" ]]; then
		upgrade_shell_script
	elif [[ ${determine_type} = "10" ]]; then
		prevent_uninstall_check
		upgrade_program
		restart_service
	elif [[ ${determine_type} = "11" ]]; then
		prevent_uninstall_check
		uninstall_program
	elif [[ ${determine_type} = "12" ]]; then
		prevent_uninstall_check
		start_service
	elif [[ ${determine_type} = "13" ]]; then
		prevent_uninstall_check
		stop_service
	elif [[ ${determine_type} = "14" ]]; then
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
			wget -O "/etc/v2ray/config.json" "https://raw.githubusercontent.com/1715173329/v2ray-onekey/master/configs/socks5.json"
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
			stty erase '^H' && read -p "请输入Socks的用户名(默认：username)：" install_socks_username
			if [[ ${install_socks_username} = "" ]]; then
				install_socks_username="username"
			else
				sed -i "s/username/${install_socks_username}/g" "/etc/v2ray/config.json"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}SS加密配置成功。"
				else
					clear
					echo -e "${error_font}SS加密配置失败！"
					clear_install
					exit 1
				fi
			fi
			stty erase '^H' && read -p "请输入Socks的密码(默认：password)：" install_socks_password
			if [[ ${install_socks_password} = "" ]]; then
				install_socks_password="password"
			else
				sed -i "s/password/${install_socks_password}/g" "/etc/v2ray/config.json"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}SS加密配置成功。"
				else
					clear
					echo -e "${error_font}SS加密配置失败！"
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
			wget -O "/etc/v2ray/config.json" "https://raw.githubusercontent.com/1715173329/v2ray-onekey/master/configs/tcp-http.json"
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}V2Ray 配置文件下载成功。"
			else
				clear
				echo -e "${error_font}V2Ray 配置文件下载失败！"
				clear_install
				exit 1
			fi
			clear
			install_port="80"
			check_port
			sed -i "s/UserUUID/${UUID}/g" "/etc/v2ray/config.json"
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}V2Ray UUID配置成功。"
			else
				clear
				echo -e "${error_font}V2Ray UUID配置失败！"
				clear_install
				exit 1
			fi
			clear
			stty erase '^H' && read -p "请输入伪装域名，多个域名请使用英文逗号\",\"隔开(默认：cache.m.iqiyi.com)：" false_domain
			if [[ ${false_domain} = "" ]]; then
				false_domain="cache.m.iqiyi.com"
			else
				sed -i "s/cache.m.iqiyi.com/${false_domain}/g" "/etc/v2ray/config.json"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}V2Ray 伪装域名配置成功。"
				else
					clear
					echo -e "${error_font}V2Ray 伪装域名配置失败！"
					clear_install
					exit 1
				fi
			fi
			echo "2" > /etc/v2ray/install_type.txt
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
		elif [[ ${determine_type} = "3" ]]; then
			clear
			echo -e "正在安装acme.sh中..."
			curl https://get.acme.sh | sh
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}acme.sh 安装成功。"
			else
				clear
				echo -e "${error_font}acme.sh 安装失败，请检查相关依赖是否正确安装。"
				clear_install
				exit 1
			fi
			wget -O "/etc/v2ray/config.json" "https://raw.githubusercontent.com/1715173329/v2ray-onekey/master/configs/tcp-tls.json"
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}V2Ray 配置文件下载成功。"
			else
				clear
				echo -e "${error_font}V2Ray 配置文件下载失败！"
				clear_install
				exit 1
			fi
			clear
			install_port="443"
			check_port
			sed -i "s/UserUUID/${UUID}/g" "/etc/v2ray/config.json"	
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}V2Ray UUID配置成功。"
			else
				clear
				echo -e "${error_font}V2Ray UUID配置失败！"
				clear_install
				exit 1
			fi
			clear
			stty erase '^H' && read -p "请输入您的域名：" install_domain
			if [[ ${install_domain} = "" ]]; then
				clear
				echo -e "${error_font}请输入您的域名。"
				clear_linstall
				exit 1
			else
				clear
				echo -e "正在签发证书中..."
				bash ~/.acme.sh/acme.sh --issue -d ${install_domain} --standalone -k ec-256 --force
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}证书生成成功。"
					bash ~/.acme.sh/acme.sh --installcert -d ${install_domain} --fullchainpath /etc/v2ray/pem.pem --keypath /etc/v2ray/key.key --ecc
					if [[ $? -eq 0 ]];then
						clear
						echo -e "${ok_font}证书配置成功。"
					else
						clear
						echo -e "${error_font}证书配置失败！"
						clear_install
						exit 1
					fi
				else
					clear
					echo -e "${error_font}证书生成失败！"
					clear_install
					exit 1
				fi
				sed -i "s/V2rayAddress/${install_domain}/g" "/etc/v2ray/config.json"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}V2Ray 域名配置成功。"
				else
					clear
					echo -e "${error_font}V2Ray 域名配置失败！"
					clear_install
					exit 1
				fi
				echo "${install_domain}" > /etc/v2ray/full_domain.txt
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}V2Ray 域名写入成功。"
				else
					clear
					echo -e "${error_font}V2Ray 域名写入失败！"
					clear_install
					exit 1
				fi
			fi
			echo "3" > /etc/v2ray/install_type.txt
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
		elif [[ ${determine_type} = "4" ]]; then
			wget -O "/etc/v2ray/config.json" "https://raw.githubusercontent.com/1715173329/v2ray-onekey/master/configs/mkcp-utp.json"
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}V2Ray 配置文件下载成功。"
			else
				clear
				echo -e "${error_font}V2Ray 配置文件下载失败！"
				clear_install
				exit 1
			fi
			clear
			input_port
			sed -i "s/UserUUID/${UUID}/g" "/etc/v2ray/config.json"
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}V2Ray UUID配置成功。"
			else
				clear
				echo -e "${error_font}V2Ray UUID配置失败！"
				clear_install
				exit 1
			fi
			echo "4" > /etc/v2ray/install_type.txt
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
		elif [[ ${determine_type} = "5" ]]; then
			wget -O "/etc/v2ray/config.json" "https://raw.githubusercontent.com/1715173329/v2ray-onekey/master/configs/mkcp-srtp.json"
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}V2Ray 配置文件下载成功。"
			else
				clear
				echo -e "${error_font}V2Ray 配置文件下载失败！"
				clear_install
				exit 1
			fi
			clear
			input_port
			sed -i "s/UserUUID/${UUID}/g" "/etc/v2ray/config.json"
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}V2Ray UUID配置成功。"
			else
				clear
				echo -e "${error_font}V2Ray UUID配置失败！"
				clear_install
				exit 1
			fi
			echo "5" > /etc/v2ray/install_type.txt
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
		elif [[ ${determine_type} = "6" ]]; then
			wget -O "/etc/v2ray/config.json" "https://raw.githubusercontent.com/1715173329/v2ray-onekey/master/configs/mkcp-srtp-dynport.json"
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}V2Ray 配置文件下载成功。"
			else
				clear
				echo -e "${error_font}V2Ray 配置文件下载失败！"
				clear_install
				exit 1
			fi
			clear
			input_port
			sed -i "s/UserUUID/${UUID}/g" "/etc/v2ray/config.json"
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}V2Ray UUID配置成功。"
			else
				clear
				echo -e "${error_font}V2Ray UUID配置失败！"
				clear_install
				exit 1
			fi
			stty erase '^H' && read -p "请输入动态端口范围(默认范围：60000-61315)：" install_dynport
			if [[ ${install_dynport} = "" ]]; then
				install_dynport="60000-61315"
			else
				sed -i "s/60000-61315/${install_dynport}/g" "/etc/v2ray/config.json"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}V2Ray 动态端口配置成功。"
				else
					clear
					echo -e "${error_font}V2Ray 动态端口配置失败！"
					clear_install
					exit 1
				fi
			fi
			echo "6" > /etc/v2ray/install_type.txt
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
		elif [[ ${determine_type} = "7" ]]; then
			clear
			echo -e "正在安装acme.sh中..."
			curl https://get.acme.sh | sh
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}acme.sh 安装成功。"
			else
				clear
				echo -e "${error_font}acme.sh 安装失败，请检查相关依赖是否正确安装。"
				clear_install
				exit 1
			fi
			wget -O "/etc/v2ray/config.json" "https://raw.githubusercontent.com/1715173329/v2ray-onekey/master/configs/h2-path.json"
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}V2Ray 配置文件下载成功。"
			else
				clear
				echo -e "${error_font}V2Ray 配置文件下载失败！"
				clear_install
				exit 1
			fi
			clear
			install_port="443"
			check_port
			sed -i "s/UserUUID/${UUID}/g" "/etc/v2ray/config.json"	
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}V2Ray UUID配置成功。"
			else
				clear
				echo -e "${error_font}V2Ray UUID配置失败！"
				clear_install
				exit 1
			fi
			clear
			stty erase '^H' && read -p "请输入您的域名：" install_domain
			if [[ ${install_domain} = "" ]]; then
				clear
				echo -e "${error_font}请输入您的域名。"
				clear_install
				exit 1
			else
				clear
				echo -e "正在签发证书中..."
				bash ~/.acme.sh/acme.sh --issue -d ${install_domain} --standalone -k ec-256 --force
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}证书生成成功。"
					bash ~/.acme.sh/acme.sh --installcert -d ${install_domain} --fullchainpath /etc/v2ray/pem.pem --keypath /etc/v2ray/key.key --ecc
					if [[ $? -eq 0 ]];then
						clear
						echo -e "${ok_font}证书配置成功。"
					else
						clear
						echo -e "${error_font}证书配置失败！"
						clear_install
						exit 1
					fi
				else
					clear
					echo -e "${error_font}证书生成失败！"
					clear_install
					exit 1
				fi
				sed -i "s/V2rayAddress/${install_domain}/g" "/etc/v2ray/config.json"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}V2Ray 域名配置成功。"
				else
					clear
					echo -e "${error_font}V2Ray 域名配置失败！"
					clear_install
					exit 1
				fi
				echo "${install_domain}" > /etc/v2ray/full_domain.txt
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}V2Ray 域名写入成功。"
				else
					clear
					echo -e "${error_font}V2Ray 域名写入失败！"
					clear_install
					exit 1
				fi
				sed -i "s/PathUUID/${UUID2}/g" "/etc/v2ray/config.json"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}V2Ray UUID配置成功。"
				else
					clear
					echo -e "${error_font}V2Ray UUID配置失败！"
					clear_install
					exit 1
				fi
			fi
		elif [[ ${determine_type} = "8" ]]; then
			clear
			echo -e "正在安装acme.sh中..."
			curl https://get.acme.sh | sh
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}acme.sh 安装成功。"
			else
				clear
				echo -e "${error_font}acme.sh 安装失败，请检查相关依赖是否正确安装。"
				clear_install
				exit 1
			fi
			bash <(curl https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/caddy_install.sh)
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}Caddy 安装成功。"
			else
				clear
				echo -e "${error_font}Caddy 安装失败，请检查相关依赖是否正确安装。"
				clear_install
				exit 1
			fi
			wget -O "/etc/v2ray/config.json" "https://raw.githubusercontent.com/1715173329/v2ray-onekey/master/configs/websocket-tls-website-path.json"
			wget -O "/usr/local/caddy/Caddyfile" "https://raw.githubusercontent.com/1715173329/v2ray-onekey/master/configs/websocket-tls-website-path.Caddyfile"
			clear
			install_port="443"
			check_port
			sed -i "s/UserUUID/${UUID}/g" "/etc/v2ray/config.json"	
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}V2Ray UUID配置成功。"
			else
				clear
				echo -e "${error_font}V2Ray UUID配置失败！"
				clear_install
				exit 1
			fi
			clear
			stty erase '^H' && read -p "请输入您的域名：" install_domain
			if [[ ${install_domain} = "" ]]; then
				clear
				echo -e "${error_font}请输入您的域名。"
				clear_install
				exit 1
			else
				clear
				echo -e "正在签发证书中..."
				bash ~/.acme.sh/acme.sh --issue -d ${install_domain} --standalone -k ec-256 --force
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}证书生成成功。"
					bash ~/.acme.sh/acme.sh --installcert -d ${install_domain} --fullchainpath /etc/v2ray/pem.pem --keypath /etc/v2ray/key.key --ecc
					if [[ $? -eq 0 ]];then
						clear
						echo -e "${ok_font}证书配置成功。"
					else
						clear
						echo -e "${error_font}证书配置失败！"
						clear_install
						exit 1
					fi
				else
					clear
					echo -e "${error_font}证书生成失败！"
					clear_install
					exit 1
				fi
				sed -i "s/V2rayAddress/${install_domain}/g" "/etc/v2ray/config.json"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}V2Ray 域名配置成功。"
				else
					clear
					echo -e "${error_font}V2Ray 域名配置失败！"
					clear_install
					exit 1
				fi
				echo "${install_domain}" > /etc/v2ray/full_domain.txt
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}V2Ray 域名写入成功。"
				else
					clear
					echo -e "${error_font}V2Ray 域名写入失败！"
					clear_install
					exit 1
				fi
				sed -i "s/PathUUID/${UUID2}/g" "/etc/v2ray/config.json"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}V2Ray UUID配置成功。"
				else
					clear
					echo -e "${error_font}V2Ray UUID配置失败！"
					clear_install
					exit 1
				fi
				sed -i "s/PathUUID/${UUID2}/g" "/usr/local/caddy/Caddyfile"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}Caddy UUID配置成功。"
				else
					clear
					echo -e "${error_font}Caddy UUID配置失败！"
					clear_install
					exit 1
				fi
				sed -i "s/V2rayAddress/${install_domain}/g" "/usr/local/caddy/Caddyfile"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}Caddy 域名配置成功。"
				else
					clear
					echo -e "${error_font}Caddy 域名配置失败！"
					clear_install
					exit 1
				fi
				sed -i "s/V2RayListenPort/${v2_listen_port}/g" "/etc/v2ray/config.json"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}V2Ray 监听端口配置成功。"
				else
					clear
					echo -e "${error_font}V2Ray 监听端口配置失败！"
					clear_install
					exit 1
				fi
				sed -i "s/V2RayListenPort/${v2_listen_port}/g" "/usr/local/caddy/Caddyfile"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}Caddy 监听端口配置成功。"
				else
					clear
					echo -e "${error_font}Caddy 监听端口配置失败！"
					clear_install
					exit 1
				fi
				mkdir /etc/v2ray/pages
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}创建文件夹成功。"
				else
					clear
					echo -e "${error_font}创建文件夹失败！"
					clear_install
					exit 1
				fi
				cd /etc/v2ray/pages
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}进入文件夹成功。"
				else
					clear
					echo -e "${error_font}进入文件夹失败！"
					clear_install
					exit 1
				fi
				wget -O "/etc/v2ray/pages/v2ray-page.zip" "https://github.com/1715173329/v2ray-onekey/blob/master/pages/v2ray-webpage.zip?raw=true"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}下载网页文件压缩包成功。"
				else
					clear
					echo -e "${error_font}下载网页文件压缩包失败！"
					clear_install
					exit 1
				fi
				unzip /etc/v2ray/pages/v2ray-page.zip
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}解压网页文件成功。"
				else
					clear
					echo -e "${error_font}解压网页文件失败！"
					clear_install
					exit 1
				fi
				rm -rf /etc/v2ray/pages/v2ray-page.zip
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}删除网页文件压缩包成功。"
				else
					clear
					echo -e "${error_font}删除网页文件压缩包失败！"
					clear_install
					exit 1
				fi
			fi
			echo "8" > /etc/v2ray/install_type.txt
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}写入安装信息成功。"
			else
				clear
				echo -e "${error_font}写入安装信息失败！"
				clear_install
				exit 1
			fi
				cd /root/
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}返回root文件夹成功。"
				else
					clear
					echo -e "${error_font}返回root文件夹失败！"
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
	clear
	stty erase '^H' && read -p "您是否需要卸载Caddy？[Y/N,Default:N]" uninstall_caddy_right
	if [[ ${uninstall_caddy_right} == [Yy] ]]; then
		if [[ ${v2ray_status} = "${red_fontcolor}未安装${default_fontcolor}" ]]; then
			clear
			echo -e "${error_font}您未安装Caddy。"
		else
			service caddy stop
			update-rc.d -f caddy remove
			rm -rf /etc/init.d/caddy
			rm -rf /root/.caddy
			rm -rf /usr/local/caddy
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}Caddy卸载成功。"
			else
				clear
				echo -e "${error_font}Caddy卸载失败！"
			fi
		fi
	else
		clear
		echo -e "${ok_font}取消卸载Caddy成功。"
	fi
}

function upgrade_shell_script(){
	clear
	echo -e "正在更新脚本中..."
	filepath=$(cd "$(dirname "$0")"; pwd)
	filename=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
	curl -O https://raw.githubusercontent.com/1715173329/v2ray-onekey/master/v2ray-go.sh
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}脚本更新成功，脚本位置：\"${green_backgroundcolor}${filename}/v2ray-go.sh${default_fontcolor}\"，使用：\"${green_backgroundcolor}bash ${filename}/v2ray-go.sh${default_fontcolor}\"。"
	else
		clear
		echo -e "${error_font}脚本更新失败！"
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
	install_type=$(cat /etc/v2ray/install_type.txt)
	if [ "${install_type}" -lt "8" ]; then
		if [[ ${v2ray_pid} -eq 0 ]]; then
			service v2ray start
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}V2Ray 启动成功。"
				exit 0
			else
				clear
				echo -e "${error_font}V2Ray 启动失败！"
				exit 1
			fi
		else
			clear
			echo -e "${error_font}V2Ray 正在运行。"
			exit 1
		fi
	else
		if [[ ${v2ray_pid} -eq 0 ]]; then
			service v2ray start
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}V2Ray 启动成功。"
			else
				clear
				echo -e "${error_font}V2Ray 启动失败！"
			fi
		else
			clear
			echo -e "${error_font}V2Ray 正在运行。"
		fi
		if [[ ${caddy_pid} -eq 0 ]]; then
			service caddy start
			if [[ $? -eq 0 ]];then
				echo -e "${ok_font}Caddy 启动成功。"
				exit 0
			else
				echo -e "${error_font}Caddy 启动失败！"
				exit 1
			fi
		else
			echo -e "${error_font}Caddy 正在运行。"
			exit 1
		fi
	fi
}

function stop_service(){
	clear
	echo -e "正在停止服务中..."
	install_type=$(cat /etc/v2ray/install_type.txt)
	if [ "${install_type}" -lt "8" ]; then
		if [[ ${v2ray_pid} -eq 0 ]]; then
			clear
			echo -e "${error_font}V2Ray 未在运行。"
		else
			service v2ray stop
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}V2Ray 停止成功。"
				exit 0
			else
				clear
				echo -e "${error_font}V2Ray 停止失败！"
				exit 1
			fi
		fi
	else
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
			fi
		fi
		if [[ ${caddy_pid} -eq 0 ]]; then
			echo -e "${error_font}Caddy 未在运行。"
		else
			service caddy stop
			if [[ $? -eq 0 ]];then
				echo -e "${ok_font}Caddy 停止成功。"
				exit 0
			else
				echo -e "${error_font}Caddy 停止失败！"
				exit 1
			fi
		fi
	fi
}

function restart_service(){
	clear
	echo -e "正在重启服务中..."
	install_type=$(cat /etc/v2ray/install_type.txt)
	if [ "${install_type}" -lt "8" ]; then
		service v2ray restart
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}V2Ray 重启成功。"
		else
			clear
			echo -e "${error_font}V2Ray 重启失败！"
		fi
	else
		service v2ray restart
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}V2Ray 重启成功。"
		else
			clear
			echo -e "${error_font}V2Ray 重启失败！"
		fi
		service caddy restart
		if [[ $? -eq 0 ]];then
			echo -e "${ok_font}Caddy 重启成功。"
		else
			echo -e "${error_font}Caddy 重启失败！"
		fi
	fi
}

function prevent_install_check(){
	clear
	echo -e "正在检测安装状态中..."
	if [[ ${determine_type} -lt 9 ]]; then
		if [[ ${install_status} = "${green_fontcolor}已安装${default_fontcolor}" ]]; then
			echo -e "${error_font}您已经安装过了，请勿再次安装，若您需要切换至其他模式，请先卸载后再使用安装功能。"
			exit 1
		elif [[ ${v2ray_status} = "${red_fontcolor}未安装${default_fontcolor}" ]]; then
			if [[ ${determine_type} -lt 8 ]]; then
				echo -e "${ok_font}检测完毕，符合要求，正在执行命令中..."
			else
				if [[ ${caddy_status} = "${red_fontcolor}未安装${default_fontcolor}" ]]; then
					echo -e "${ok_font}检测完毕，符合要求，正在执行命令中..."
				else
					echo -e "${error_font}您的VPS上已经安装Caddy，请勿再次安装，若您需要使用本脚本，请先卸载后再使用安装功能。"
					exit 1
				fi
			fi
		else
			echo -e "${error_font}您的VPS上已经安装V2Ray，请勿再次安装，若您需要使用本脚本，请先卸载后再使用安装功能。"
			exit 1
		fi
	fi
}

function uninstall_program(){
	clear
	echo -e "正在卸载中..."
	install_type=$(cat /etc/v2ray/install_type.txt)
	if [ "${install_type}" -lt "8" ]; then
		full_domain=$(cat /etc/v2ray/full_domain.txt)
		delete_domain
		bash ~/.acme.sh/acme.sh --revoke -d ${full_domain} --ecc
		bash ~/.acme.sh/acme.sh --remove -d ${full_domain} --ecc
		rm -rf ~/.acme.sh
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
	else
		full_domain=$(cat /etc/v2ray/full_domain.txt)
		delete_domain
		bash ~/.acme.sh/acme.sh --revoke -d ${full_domain} --ecc
		bash ~/.acme.sh/acme.sh --remove -d ${full_domain} --ecc
		rm -rf ~/.acme.sh
		service v2ray stop
		update-rc.d -f v2ray remove
		rm -rf /etc/init.d/v2ray
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
		service caddy stop
		update-rc.d -f caddy remove
		rm -rf /etc/init.d/caddy
		rm -rf /root/.caddy
		rm -rf /usr/local/caddy
		if [[ $? -eq 0 ]];then
			echo -e "${ok_font}Caddy卸载成功。"
		else
			echo -e "${error_font}Caddy卸载失败！"
		fi
	fi
}

function upgrade_program(){
	clear
	echo -e "正在更新程序中..."
	install_type=$(cat /etc/v2ray/install_type.txt)
	if [ "${install_type}" -lt "8" ]; then
		bash <(curl https://install.direct/go.sh)
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}V2Ray 更新成功。"
		else
			clear
			echo -e "${error_font}V2Ray 更新失败！"
		fi
	else
		bash <(curl https://install.direct/go.sh)
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}V2Ray 更新成功。"
		else
			clear
			echo -e "${error_font}V2Ray 更新失败！"
		fi
		bash <(curl https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/caddy_install.sh)
		if [[ $? -eq 0 ]];then
			echo -e "${ok_font}Caddy 更新成功。"
		else
			echo -e "${error_font}Caddy 更新失败！"
		fi
	fi
}

function clear_install(){
	clear
	echo -e "正在卸载中..."
	if [ "${determine_type}" -le "4" ]; then
		full_domain=$(cat /etc/v2ray/full_domain.txt)
		delete_domain
		bash ~/.acme.sh/acme.sh --revoke -d ${full_domain} --ecc
		bash ~/.acme.sh/acme.sh --remove -d ${full_domain} --ecc
		rm -rf ~/.acme.sh
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
	elif [ "${determine_type}" -eq "5" ];then
		full_domain=$(cat /etc/v2ray/full_domain.txt)
		delete_domain
		bash ~/.acme.sh/acme.sh --revoke -d ${full_domain} --ecc
		bash ~/.acme.sh/acme.sh --remove -d ${full_domain} --ecc
		rm -rf ~/.acme.sh
		service v2ray stop
		update-rc.d -f v2ray remove
		rm -rf /etc/init.d/v2ray
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
		service caddy stop
		update-rc.d -f caddy remove
		rm -rf /etc/init.d/caddy
		rm -rf /root/.caddy
		rm -rf /usr/local/caddy
		if [[ $? -eq 0 ]];then
			echo -e "${ok_font}Caddy卸载成功。"
		else
			echo -e "${error_font}Caddy卸载失败！"
		fi
	fi
}

function os_update(){
	clear
	echo -e "正在安装/更新系统组件中..."
	clear
	apt-get -y update
	apt-get -y upgrade
	apt-get -y install wget curl ntpdate unzip socat lsof cron iptables
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
	echo "正在生成基础信息中..."
	hostname=$(hostname)
	Address=$(curl https://ipinfo.io/ip)
	UUID=$(cat /proc/sys/kernel/random/uuid)
	UUID2=$(cat /proc/sys/kernel/random/uuid)
	let v2_listen_port=$RANDOM+10000
	if [[ ${hostname} = "" ]]; then
		clear
		echo -e "${error_font}读取Hostname失败！"
		exit 1
	elif [[ ${Address} = "" ]]; then
		clear
		echo -e "${error_font}读取vps_ip失败！"
		exit 1
	elif [[ ${UUID} = "" ]]; then
		clear
		echo -e "${error_font}生成UUID失败！"
		exit 1
	elif [[ ${UUID2} = "" ]]; then
		clear
		echo -e "${error_font}生成UUID2失败！"
		exit 1
	elif [[ ${v2_listen_port} = "" ]]; then
		clear
		echo -e "${error_font}生成V2Ray监听端口失败！"
		exit 1
	else
		clear
		echo -e "${ok_font}您的主机名为：${hostname}"
		echo -e "${ok_font}您的vps_ip为：${Address}"
		echo -e "${ok_font}生成的UUID为：${UUID}"
		echo -e "${ok_font}生成的UUID2为：${UUID2}"
		echo -e "${ok_font}生成V2Ray监听端口为：${v2_listen_port}"
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

function echo_v2ray_config(){
	if [[ ${determine_type} = "1" ]]; then
		clear
		echo -e "您的连接信息如下："
		echo -e "地址(Hostname)：${Address}"
		echo -e "端口(Port)：${install_port}"
		echo -e "用户名(Username)：${install_socks_username}"
		echo -e "密码(Password)：${install_socks_password}"
		echo -e "代理协议(Proxy Type)：socks5"
		echo -e "Telegram设置链接： ${green_backgroundcolor}https://t.me/socks?server=${Address}&port=${install_port}&user=${install_socks_username}&pass=${install_socks_password}${default_fontcolor}"
	elif [[ ${determine_type} = "2" ]]; then
		clear
		vmesslink="vmess://"$(echo -e "{
		  \"ps\": \"${hostname}\",
		  \"add\": \"${Address}\",
		  \"port\": \"${install_port}\",
		  \"id\": \"${UUID}\",
		  \"aid\": \"100\",
		  \"net\": \"tcp\",
		  \"type\": \"http\",
		  \"host\": \"${false_domain}\",
		  \"tls\": \"\"
		  }" | base64)
		echo -e "您的连接信息如下："
		echo -e "别名(Remarks)：${hostname}"
		echo -e "地址(Address)：{Address}"
		echo -e "端口(Port)：${install_port}"
		echo -e "用户ID(ID)：${UUID}"
		echo -e "额外ID(AlterID)：100"
		echo -e "加密方式(Security)：aes-128-gcm"
		echo -e "传输协议(Network）：tcp"
		echo -e "伪装类型：http"
		echo -e "伪装域名/其他项：${false_domain}"
		echo -e "Vmess链接：${green_backgroundcolor}${vmesslink}${default_fontcolor}"
	elif [[ ${determine_type} = "3" ]]; then
		clear
		vmesslink="vmess://"$(echo -e "{
		  \"ps\": \"${hostname}\",
		  \"add\": \"${install_domain}\",
		  \"port\": \"${install_port}\",
		  \"id\": \"${UUID}\",
		  \"aid\": \"100\",
		  \"net\": \"tcp\",
		  \"type\": \"none\",
		  \"host\": \"\",
		  \"tls\": \"tls\"
		  }" | base64)
		echo -e "您的连接信息如下："
		echo -e "别名(Remarks)：${hostname}"
		echo -e "地址(Address)：${install_domain}"
		echo -e "端口(Port)：${install_port}"
		echo -e "用户ID(ID)：${UUID}"
		echo -e "额外ID(AlterID)：100"
		echo -e "加密方式(Security)：none"
		echo -e "传输协议(Network）：tcp"
		echo -e "底层传输安全(TLS）：tls"
		echo -e "Vmess链接：${green_backgroundcolor}${vmesslink}${default_fontcolor}"
	elif [[ ${determine_type} = "4" ]]; then
		clear
		vmesslink="vmess://"$(echo -e "{
		  \"ps\": \"${hostname}\",
		  \"add\": \"${Address}\",
		  \"port\": \"${install_port}\",
		  \"id\": \"${UUID}\",
		  \"aid\": \"100\",
		  \"net\": \"kcp\",
		  \"type\": \"utp\",
		  \"host\": \"\",
		  \"tls\": \"\"
		  }" | base64)
		echo -e "您的连接信息如下："
		echo -e "别名(Remarks)：${hostname}"
		echo -e "地址(Address)：${Address}"
		echo -e "端口(Port)：${install_port}"
		echo -e "用户ID(ID)：${UUID}"
		echo -e "额外ID(AlterID)：100"
		echo -e "加密方式(Security)：aes-128-gcm"
		echo -e "传输协议(Network）：kcp"
		echo -e "伪装类型：utp"
		echo -e "Vmess链接：${green_backgroundcolor}${vmesslink}${default_fontcolor}"
	elif [[ ${determine_type} = "5" ]]; then
		clear
		vmesslink="vmess://"$(echo -e "{
		  \"ps\": \"${hostname}\",
		  \"add\": \"${Address}\",
		  \"port\": \"${install_port}\",
		  \"id\": \"${UUID}\",
		  \"aid\": \"100\",
		  \"net\": \"kcp\",
		  \"type\": \"srtp\",
		  \"host\": \"\",
		  \"tls\": \"\"
		  }" | base64)
		echo -e "您的连接信息如下："
		echo -e "别名(Remarks)：${hostname}"
		echo -e "地址(Address)：${Address}"
		echo -e "端口(Port)：${install_port}"
		echo -e "用户ID(ID)：${UUID}"
		echo -e "额外ID(AlterID)：100"
		echo -e "加密方式(Security)：aes-128-gcm"
		echo -e "传输协议(Network）：kcp"
		echo -e "伪装类型：srtp"
		echo -e "Vmess链接：${green_backgroundcolor}${vmesslink}${default_fontcolor}"
	elif [[ ${determine_type} = "6" ]]; then
		clear
		vmesslink="vmess://"$(echo -e "{
		  \"ps\": \"${hostname}\",
		  \"add\": \"${Address}\",
		  \"port\": \"${install_port}\",
		  \"id\": \"${UUID}\",
		  \"aid\": \"100\",
		  \"net\": \"kcp\",
		  \"type\": \"srtp\",
		  \"host\": \"\",
		  \"tls\": \"\"
		  }" | base64)
		echo -e "您的连接信息如下："
		echo -e "别名(Remarks)：${hostname}"
		echo -e "地址(Address)：${Address}"
		echo -e "端口(Port)：${install_port}"
		echo -e "用户ID(ID)：${UUID}"
		echo -e "额外ID(AlterID)：100"
		echo -e "加密方式(Security)：aes-128-gcm"
		echo -e "传输协议(Network）：kcp"
		echo -e "伪装类型：srtp"
		echo -e "Vmess链接：${green_backgroundcolor}${vmesslink}${default_fontcolor}"
	elif [[ ${determine_type} = "7" ]]; then
		clear
		vmesslink="您选择的协议：H2 暂不支持生成vmess链接。"
		echo -e "您的连接信息如下："
		echo -e "别名(Remarks)：${hostname}"
		echo -e "地址(Address)：${install_domain}"
		echo -e "端口(Port)：${install_port}"
		echo -e "用户ID(ID)：${UUID}"
		echo -e "额外ID(AlterID)：100"
		echo -e "加密方式(Security)：none"
		echo -e "传输协议(Network）：h2"
		echo -e "伪装类型：none"
		echo -e "伪装域名/其他项：/fuckgfw_gfwmotherfuckingboom/${UUID2}"
		echo -e "Vmess链接：${red_backgroundcolor}${vmesslink}${default_fontcolor}"
	fi
	elif [[ ${determine_type} = "8" ]]; then
		clear
		vmesslink="vmess://"$(echo -e "{
		  \"ps\": \"${hostname}\",
		  \"add\": \"${install_domain}\",
		  \"port\": \"${install_port}\",
		  \"id\": \"${UUID}\",
		  \"aid\": \"100\",
		  \"net\": \"ws\",
		  \"type\": \"none\",
		  \"host\": \"/fuckgfw_gfwmotherfuckingboom/${UUID2}\",
		  \"tls\": \"tls\"
		  }" | base64)
		echo -e "您的连接信息如下："
		echo -e "别名(Remarks)：${hostname}"
		echo -e "地址(Address)：${install_domain}"
		echo -e "端口(Port)：${install_port}"
		echo -e "用户ID(ID)：${UUID}"
		echo -e "额外ID(AlterID)：100"
		echo -e "加密方式(Security)：none"
		echo -e "传输协议(Network）：ws"
		echo -e "伪装类型：none"
		echo -e "伪装域名/其他项：/fuckgfw_gfwmotherfuckingboom/${UUID2}"
		echo -e "Vmess链接：${green_backgroundcolor}${vmesslink}${default_fontcolor}"
	fi
	echo -e "${vmesslink}" > /etc/v2ray/vmess_link.txt
}

function main(){
	set_fonts_colors
	check_os
	check_install_status
	echo_install_list
}

	main