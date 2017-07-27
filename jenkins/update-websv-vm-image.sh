#!/bin/bash -xe

#- リソースグループ作成
RGNAME=user0008-webapp-image${BUILD_NUMBER}-rg
az configure --defaults "group=''"
az group create -l japaneast -n ${RGNAME}
az configure --defaults group=${RGNAME}

#- VM作成
az vm create -n websv0 \
    --public-ip-address webapp-pip \
    --nsg webapp-websv-nsg \
    --size Standard_F1 \
    --image OpenLogic:CentOS:7.3:7.3.20170707 \
    --storage-sku Standard_LRS \
    --os-disk-name websv-osdisk \
    --admin-username devops \
    --ssh-key-value ~/.ssh/id_rsa.pub

#- VM作成後のウェイト
sleep 10

#- IPアドレスを確認
az network public-ip show -n webapp-pip -o tsv --query ipAddress | tee ./websv0-public-ip

#- インストーラをVMに送って実行
ssh-keyscan $(cat websv0-public-ip) | tee -a ~/.ssh/known_hosts
scp -pq ./websv/websv-install.sh \
    devops@$(cat websv0-public-ip):/tmp/websv-install.sh
ssh -nT devops@$(cat ./websv0-public-ip) "sudo /tmp/websv-install.sh"

#- プロビジョニング解除・停止・一般化
ssh -nT devops@$(cat ./websv0-public-ip) "sudo waagent -force -deprovision+user"
az vm deallocate -n websv0
az vm generalize -n websv0

#- イメージ作成
az image create -n webapp-websv-image --os-type Linux --source websv0

#- イメージ以外のリソースを削除
az vm delete -y -n websv0
az resource list -g ${RGNAME} \
    --query "[?type=='Microsoft.Network/networkInterfaces'].name" -o tsv \
    | tee >(cat >&2) \
    | xargs -I TARGET az network nic delete -n TARGET
az resource list -g ${RGNAME} \
    --query "[?type=='Microsoft.Compute/disks'].name" -o tsv \
    | tee >(cat >&2) \
    | xargs -I TARGET az disk delete -y -n TARGET
az network public-ip delete -n webapp-pip
rm -f ./websv0-public-ip
az resource list -g ${RGNAME} \
    --query "[?type=='Microsoft.Network/virtualNetworks'].name" -o tsv \
    | tee >(cat >&2) \
    | xargs -I TARGET az network vnet delete -n TARGET
az resource list -g ${RGNAME}     --query "[?type=='Microsoft.Network/networkSecurityGroups'].name" -o tsv \
    | tee >(cat >&2) \
    | xargs -I TARGET az network nsg delete -n TARGET

#- 新しいマシンイメージの ID を取得して格納
az image list -g ${RGNAME} --query "[?name=='webapp-websv-image'].id" \
    -o tsv | tee ./websv/websv-image-azure-id

#- マシンイメージの ID を格納したファイルが変更されたことを git にコミット
git add ./websv/websv-image-azure-id
git commit -m "Updated websv vm image id - ${BUILD_TAG}"

#- 上のコミットされた内容は、Git Publisher の機能で push される見込み
#

