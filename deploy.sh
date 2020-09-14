#!/usr/bin/env sh

BUSINESS=""

# 当发生错误时中止脚本
set -e

#接收用户输入参数
while getopts c: opt
do
	case "$opt" in
		c)BUSINESS=${OPTARG};;
		*);;
	esac;
done;

# 添加文件到缓冲区
git add -A

# 提交文件
git commit -m $BUSINESS

# 推送到远程
git push 

cd -