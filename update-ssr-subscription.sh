#!/bin/bash

# 在 config_dir 下根据订阅 subscription_addr
#  生成 ssr-{local,redir}-node-port.json 配置文件
#
# 注意：
#  - 只创建/覆盖 .json 配置文件，*不* 删除过期 .json 配置文件
#    如需要，请在运行脚本前手动删除原所有的 .json 配置文件

##### 自行设定的配置项 #####

subscription_addr=""
config_dir="."
# defer parameter expansion 由于需要 eval 一次，\" escape 在此处是必需的
config_templ='\
{
  \"server\": \"${server}\",
  \"server_port\": ${server_port},
  \"local_address\": \"0.0.0.0\",
  \"local_port\": ${local_port},
  \"password\": \"${password}\",
  \"method\": \"${method}\",
  \"protocol\": \"${protocol}\",
  \"protocol_param\": \"${protocol_param}\",
  \"obfs\": \"${obfs}\",
  \"obfs_param\": \"${obfs_param}\",
  \"timeout\": 300,
  \"workers\": 1
}'

ssr_redir_port=1080
ssr_local_port=1081

##### END #####

# $1 -> stdout
function b64url-to-b64 () {
    line=$1
    len=$(( ${#line} % 4 ))
    if [ ${len} -eq 2 ]; then
        line+='=='
    elif [ $len -eq 3 ]; then
        line+='='
    fi

    echo ${line} | tr '_-' '/+'
}

function main () {
    # 拉取订阅

    # lines=`curl ${subscription_addr} | base64 -d | cut -b 7-` # for DEBUG
    lines=`cat ssr-subscription.base64 | base64 -d | cut -b 7-`

    while read -r line; do
        line=`b64url-to-b64 ${line} | base64 -d`

        # 1. 解析每个节点配置

        server=`echo ${line} | cut -d ':' -f 1`
        server_port=`echo ${line} | cut -d ':' -f 2`
        protocol=`echo ${line} | cut -d ':' -f 3`
        method=`echo ${line} | cut -d ':' -f 4`
        obfs=`echo ${line} | cut -d ':' -f 5`
        password_b64=`echo ${line} | cut -d ':' -f 6 | cut -d '/' -f 1`
        password=`b64url-to-b64 ${password_b64} | base64 -d`
        obfs_param_b64=`echo ${line} | cut -d '?' -f 2 | cut -d '&' -f 1 | cut -d '=' -f 2`
        obfs_param=`b64url-to-b64 ${obfs_param_b64} | base64 -d`
        protocol_param_b64=`echo ${line} | cut -d '?' -f 2 | cut -d '&' -f 2 | cut -d '=' -f 2`
        protocol_param=`b64url-to-b64 ${protocol_param_b64} | base64 -d`

        # 2. 拼接本地文件名

        node=`echo ${line} | cut -d '.' -f 1` # hammerss specific
        port=${server_port}
        echo ${node}-${port}        # DEBUG
        config_file_local="${config_dir}/ssr-local-${node}-${port}.json"
        config_file_redir="${config_dir}/ssr-redir-${node}-${port}.json"

        # 3. 写入本地文件

        local_port=${ssr_local_port}
        # 必需用 eval 以 defer parameter expansion
        # https://unix.stackexchange.com/questions/60688/how-to-defer-variable-expansion
        eval "config=\"${config_templ}\""
        echo "${config}" > ${config_file_local}

        local_port=${ssr_redir_port}
        eval "config=\"${config_templ}\""
        echo "${config}" > ${config_file_redir}

    done <<< "${lines}"

}

main $@
