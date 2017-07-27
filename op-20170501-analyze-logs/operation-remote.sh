#!/bin/bash -xe

# コマンドラインパラメータはウェブサーバの番号： 1..5
if [ $# -ne 1 ]; then
    echo "Usage: $0 <websv-no>"
    exit 1
fi
WEBSV_NO=$1  # 1..5

NUM_OF_WEBSV=5  # ウェブサーバの台数は 5

logger "Started maintenance op-20170501 on websv${WEBSV_NO}."

EXPORT_TBZ=/tmp/log-files-websv${WEBSV_NO}.tbz
OP_TMP_DIR=$(mktemp -d)

systemctl restart httpd
sleep 5

cd ${OP_TMP_DIR}
cp -fp /var/log/httpd/{access_log,error_log}* ./
journalctl -a -o export >./journald.export
tar jcf ${EXPORT_TBZ} ./*
cd /tmp/
rm -rf ${OP_TMP_DIR}

# websv1 の場合は、親として websv2..websv5 の処理を行なう
if [ ${WEBSV_NO} -eq 1 ]; then

  mkdir -p /tmp/log-files/
  mv ${EXPORT_TBZ} /tmp/log-files/
  for i in $(seq 2 ${NUM_OF_WEBSV}); do
 
    # IPアドレス
    IP=192.168.1.$((10 + ${i}))
    
    # シェルスクリプトをアップロードして実行
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -pq /tmp/operation-remote.sh webapusr@${IP}:/tmp/
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -nTA webapusr@${IP} \
        "sudo -E /tmp/operation-remote.sh ${i}"

    # 収集したログをダウンロード
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -pq webapusr@${IP}:/tmp/log-files-websv${i}.tbz /tmp/log-files/

  done

  # アーカイブを作成
  cd /tmp/
  tar cf /tmp/op-20170501-log-files.tar ./log-files/
  rm -rf /tmp/log-files/

fi

logger "Finished maintenance op-20170501 on websv${WEBSV_NO}."

