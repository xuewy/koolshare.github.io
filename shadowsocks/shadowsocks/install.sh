#! /bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

eval `dbus export ss`
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
mkdir -p /koolshare/ss
mkdir -p /tmp/ss_backup

# 判断路由架构和平台
case $(uname -m) in
	armv7l)
		if [ "`uname -o|grep Merlin`" ] && [ -d "/koolshare" ];then
			echo_date 固件平台【koolshare merlin armv7l】符合安装要求，开始安装插件！
		else
			echo_date 本插件适用于koolshare merlin armv7l固件平台，你的平台不能安装！！！
			exit 1
		fi
	;;
	*)
		echo_date 本插件适用于koolshare merlin armv7l固件平台，你的平台"$(uname -m)"不能安装！！！
		echo_date 退出安装！
		exit 1
	;;
esac

upgrade_ss_conf(){
	nodes=`dbus list ssc|grep port|cut -d "=" -f1|cut -d "_" -f4|sort -n`
	for node in $nodes
	do
		if [ "`dbus get ssconf_basic_use_rss_$node`" == "1" ];then
			#ssr
			dbus remove ssconf_basic_ss_obfs_$node
			dbus remove ssconf_basic_ss_obfs_host_$node
			dbus remove ssconf_basic_koolgame_udp_$node
		else
			if [ -n "`dbus get ssconf_basic_koolgame_udp_$node`" ];then
				#koolgame
				dbus remove ssconf_basic_rss_protocol_$node
				dbus remove ssconf_basic_rss_protocol_param_$node
				dbus remove ssconf_basic_rss_obfs_$node
				dbus remove ssconf_basic_rss_obfs_param_$node
				dbus remove ssconf_basic_ss_obfs_$node
				dbus remove ssconf_basic_ss_obfs_host_$node
			else
				#ss
				dbus remove ssconf_basic_rss_protocol_$node
				dbus remove ssconf_basic_rss_protocol_param_$node
				dbus remove ssconf_basic_rss_obfs_$node
				dbus remove ssconf_basic_rss_obfs_param_$node
				dbus remove ssconf_basic_koolgame_udp_$node
				[ -z "`dbus get ssconf_basic_ss_obfs_$node`" ] && dbus set ssconf_basic_ss_obfs_$node="0"
			fi
		fi
		dbus remove ssconf_basic_use_rss_$node
	done
	
	use_node=`dbus get ssconf_basic_node`
	[ -z "$use_node" ] && use_node="1"
	dbus remove ss_basic_server
	dbus remove ss_basic_mode
	dbus remove ss_basic_port
	dbus remove ss_basic_method
	dbus remove ss_basic_ss_obfs
	dbus remove ss_basic_ss_obfs_host
	dbus remove ss_basic_rss_protocol
	dbus remove ss_basic_rss_protocol_param
	dbus remove ss_basic_rss_obfs
	dbus remove ss_basic_rss_obfs_param
	dbus remove ss_basic_koolgame_udp
	dbus remove ss_basic_use_rss
	dbus remove ss_basic_use_kcp
	sleep 1
	[ -n "`dbus get ssconf_basic_server_$node`" ] && dbus set ss_basic_server=`dbus get ssconf_basic_server_$node`
	[ -n "`dbus get ssconf_basic_mode_$node`" ] && dbus set ss_basic_mode=`dbus get ssconf_basic_mode_$node`
	[ -n "`dbus get ssconf_basic_port_$node`" ] && dbus set ss_basic_port=`dbus get ssconf_basic_port_$node`
	[ -n "`dbus get ssconf_basic_method_$node`" ] && dbus set ss_basic_method=`dbus get ssconf_basic_method_$node`
	[ -n "`dbus get ssconf_basic_ss_obfs_$node`" ] && dbus set ss_basic_ss_obfs=`dbus get ssconf_basic_ss_obfs_$node`
	[ -n "`dbus get ssconf_basic_ss_obfs_host_$node`" ] && dbus set ss_basic_ss_obfs_host=`dbus get ssconf_basic_ss_obfs_host_$node`
	[ -n "`dbus get ssconf_basic_rss_protocol_$node`" ] && dbus set ss_basic_rss_protocol=`dbus get ssconf_basic_rss_protocol_$node`
	[ -n "`dbus get ssconf_basic_rss_protocol_param_$node`" ] && dbus set ss_basic_rss_protocol_param=`dbus get ssconf_basic_rss_protocol_param_$node`
	[ -n "`dbus get ssconf_basic_rss_obfs_$node`" ] && dbus set ss_basic_rss_obfs=`dbus get ssconf_basic_rss_obfs_$node`
	[ -n "`dbus get ssconf_basic_rss_obfs_param_$node`" ] && dbus set ss_basic_rss_obfs_param=`dbus get ssconf_basic_rss_obfs_param_$node`
	[ -n "`dbus get ssconf_basic_koolgame_udp_$node`" ] && dbus set ss_basic_koolgame_udp=`dbus get ssconf_basic_koolgame_udp_$node`
	[ -n "`dbus get ssconf_basic_use_kcp_$node`" ] && dbus set ss_basic_koolgame_udp=`dbus get ssconf_basic_use_kcp_$node`
}

[ -f "/usr/bin/versioncmp" ] && {
	SS_VERSION_OLD=`dbus get ss_basic_version_local`
	[ -z "$SS_VERSION_OLD" ] && SS_VERSION_OLD=3.6.5
	ss_comp=`/usr/bin/versioncmp $SS_VERSION_OLD 3.6.5`
	if [ "$ss_comp" == "1" ];then
		echo_date ！！！！！！！！！！！！！！！！！！！！！！！！！！!
		echo_date 检测到SS版本号为 $SS_VERSION_OLD !
		echo_date 从3.6.5开始，SS插件和之前版本的数据格式不完全兼容 !
		echo_date 此次升级将会尝试升级原先的数据 !
		echo_date 如果你安装此版本后仍然有问题，请尝试清空ss数据后重新录入 !
		echo_date ！！！！！！！！！！！！！！！！！！！！！！！！！！!
		upgrade_ss_conf
	fi
}

if [ "$ss_basic_enable" == "1" ];then
	echo_date 先关闭ss，保证文件更新成功!
	sh /koolshare/ss/ssconfig.sh stop
fi

if [ -n "`ls /koolshare/ss/postscripts/P*.sh 2>/dev/null`" ];then
	echo_date 备份触发脚本!
	find /koolshare/ss/postscripts -name "P*.sh" | xargs -i mv {} -f /tmp/ss_backup
fi

echo_date 清理旧文件
rm -rf /koolshare/ss/*
rm -rf /koolshare/scripts/ss_*
rm -rf /koolshare/webs/Main_Ss*
rm -rf /koolshare/bin/ss-redir
rm -rf /koolshare/bin/ss-tunnel
rm -rf /koolshare/bin/ss-local
rm -rf /koolshare/bin/rss-redir
rm -rf /koolshare/bin/rss-tunnel
rm -rf /koolshare/bin/rss-local
rm -rf /koolshare/bin/obfs-local
rm -rf /koolshare/bin/koolgame
rm -rf /koolshare/bin/pdu
rm -rf /koolshare/bin/haproxy
rm -rf /koolshare/bin/pdnsd
rm -rf /koolshare/bin/Pcap_DNSProxy
rm -rf /koolshare/bin/dnscrypt-proxy
rm -rf /koolshare/bin/dns2socks
rm -rf /koolshare/bin/cdns
rm -rf /koolshare/bin/client_linux_arm5
rm -rf /koolshare/bin/chinadns
rm -rf /koolshare/bin/chinadns1
rm -rf /koolshare/bin/resolveip
rm -rf /koolshare/bin/udp2raw
rm -rf /koolshare/bin/speeder*
rm -rf /koolshare/bin/v2ray
rm -rf /koolshare/bin/v2ctl
rm -rf /koolshare/res/layer
rm -rf /koolshare/res/shadowsocks.css
rm -rf /koolshare/res/icon-shadowsocks.png
rm -rf /koolshare/res/ss-menu.js
rm -rf /koolshare/res/all.png
rm -rf /koolshare/res/gfwlist.png
rm -rf /koolshare/res/chn.png
rm -rf /koolshare/res/game.png
rm -rf /koolshare/res/shadowsocks.css
rm -rf /koolshare/res/gameV2.png
rm -rf /koolshare/res/ss_proc_status.htm
find /koolshare/init.d/ -name "*socks5.sh" | xargs rm -rf

echo_date 开始复制文件！
cd /tmp

echo_date 复制相关二进制文件！此步时间可能较长！
echo_date 如果长时间没有日志刷新，请等待2分钟后进入插件看是否安装成功..。
cp -rf /tmp/shadowsocks/bin/* /koolshare/bin/
chmod 755 /koolshare/bin/*

echo_date 复制ss的脚本文件！
cp -rf /tmp/shadowsocks/ss/* /koolshare/ss/
cp -rf /tmp/shadowsocks/scripts/* /koolshare/scripts/
cp -rf /tmp/shadowsocks/install.sh /koolshare/scripts/ss_install.sh
cp -rf /tmp/shadowsocks/uninstall.sh /koolshare/scripts/uninstall_shadowsocks.sh

echo_date 复制网页文件！
cp -rf /tmp/shadowsocks/webs/* /koolshare/webs/
cp -rf /tmp/shadowsocks/res/* /koolshare/res/

echo_date 移除安装包！
rm -rf /tmp/shadowsocks* >/dev/null 2>&1

echo_date 为新安装文件赋予执行权限...
chmod 755 /koolshare/ss/cru/*
chmod 755 /koolshare/ss/rules/*
chmod 755 /koolshare/ss/*
chmod 755 /koolshare/scripts/ss*
chmod 755 /koolshare/bin/*

if [ -n "`ls /tmp/ss_backup/P*.sh 2>/dev/null`" ];then
	echo_date 恢复触发脚本!
	mkdir -p /koolshare/ss/postscripts
	find /tmp/ss_backup -name "P*.sh" | xargs -i mv {} -f /koolshare/ss/postscripts
fi

echo_date 创建一些二进制文件的软链接！
[ ! -L "/koolshare/bin/rss-tunnel" ] && ln -sf /koolshare/bin/rss-local /koolshare/bin/rss-tunnel
[ ! -L "/koolshare/bin/base64" ] && ln -sf /koolshare/bin/koolbox /koolshare/bin/base64
[ ! -L "/koolshare/bin/shuf" ] && ln -sf /koolshare/bin/koolbox /koolshare/bin/shuf
[ ! -L "/koolshare/bin/netstat" ] && ln -sf /koolshare/bin/koolbox /koolshare/bin/netstat
[ ! -L "/koolshare/bin/base64_decode" ] && ln -s /koolshare/bin/base64_encode /koolshare/bin/base64_decode
[ ! -L "/koolshare/init.d/S99socks5.sh" ] && ln -sf /koolshare/scripts/ss_socks5.sh /koolshare/init.d/S99socks5.sh

echo_date 设置一些默认值
[ -z "$ss_dns_china" ] && dbus set ss_dns_china=11
[ -z "$ss_dns_foreign" ] && dbus set ss_dns_foreign=1
[ -z "$ss_basic_ss_obfs" ] && dbus set ss_basic_ss_obfs=0
[ -z "$ss_acl_default_mode" ] && [ -n "$ss_basic_mode" ] && dbus set ss_acl_default_mode="$ss_basic_mode"
[ -z "$ss_acl_default_mode" ] && [ -z "$ss_basic_mode" ] && dbus set ss_acl_default_mode=1
[ -z "$ss_acl_default_port" ] && dbus set ss_acl_default_port=all

# 离线安装时设置软件中心内储存的版本号和连接
CUR_VERSION=`cat /koolshare/ss/version`
dbus set ss_basic_version="$CUR_VERSION"
dbus set softcenter_module_shadowsocks_install="4"
dbus set softcenter_module_shadowsocks_version="$CUR_VERSION"
dbus set softcenter_module_shadowsocks_title="科学上网"
dbus set softcenter_module_shadowsocks_description="科学上网"
dbus set softcenter_module_shadowsocks_home_url=Main_Ss_Content.asp

echo_date 一点点清理工作...
rm -rf /tmp/shadowsocks* >/dev/null 2>&1
dbus set ss_basic_install_status="0"
echo_date 插件安装成功，你为什么这么屌？！

if [ "$ss_basic_enable" == "1" ];then
	echo_date 重启ss！
	dbus set ss_basic_action=1
	sh /koolshare/ss/ssconfig.sh restart
fi
echo_date 更新完毕，请等待网页自动刷新！
