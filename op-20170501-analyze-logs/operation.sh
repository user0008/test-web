#!/bin/bash -xe

# コマンドラインパラメータを取得
if [ $# -ne 4 ]; then
    echo "Usage: $0 <ip-addr> <ssh-port> <ssh-user> <ssh-key-path>"
    exit 1
fi
PUBLIC_IP=$1    # 203.0.113.123
SSH_PORT=$2     # 1022
SSH_USER=$3     # webapusr
SSH_KEY=$4      # /home/devops/.ssh/id_rsa

# 収集したログファイルの保存先
LOG_FILES_TAR=~/op-20170501-log-files.tar

# ウェブサーバ上で実行するシェルスクリプトをアップロードして実行
eval `ssh-agent`
ssh-add ${SSH_KEY}
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -pq -P ${SSH_PORT} \
    ./operation-remote.sh \
    ${SSH_USER}@${PUBLIC_IP}:/tmp/operation-remote.sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -nTA -p ${SSH_PORT} \
    ${SSH_USER}@${PUBLIC_IP} \
    "sudo -E /tmp/operation-remote.sh 1"

# 収集したログファイルをダウンロード
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -pq -P ${SSH_PORT} \
    ${SSH_USER}@${PUBLIC_IP}:/tmp/op-20170501-log-files.tar \
    ${LOG_FILES_TAR}

