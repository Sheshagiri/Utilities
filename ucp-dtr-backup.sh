#!/bin/bash

#set these variables first or pass them from command line
ucp_version="3.0.4"
dtr_version="latest"


# the script should be called with three arguments
if [ "$#" != "3" ]
then
  echo "Usage: $0 <ucp url with port> <ucp username> <ucp password>"
  echo "Example: $0 \"https://10.10.10.10:443\" admin admin123"
  exit 1
fi

ucp_url=$1
ucp_username=$2
ucp_password=$3

DATE=`date '+%Y-%m-%d-%H-%M-%S'`


echo "##########################################################################################"
echo "###################################Starting DTR backup.###################################"
echo "##########################################################################################"

echo "DTR Version is set to $dtr_version"

echo "Starting DTR backup, backup will be saved ins backup-dtr-${DATE}.tar"

dtr_replica_id=`docker ps --format "{{.Names}}" | grep dtr | grep rethinkdb | awk -F "-" '{print$3}'`
if [ "$?" = "" ]    
then
	echo "Unable to find DTR replica id."
	exit 1
fi

docker run --log-driver none --rm -i \
	docker/dtr:$dtr_version backup  \
		--ucp-url=${ucp_url} \
		--ucp-username=${ucp_username} --ucp-password=${ucp_password} \
		--ucp-insecure-tls  --existing-replica-id=${dtr_replica_id} > backup-dtr-${DATE}.tar

if [ "$?" != "0" ]    
then
	echo "##########################################################################################"
	echo "###################################DTR backup failed.#####################################"
	echo "##########################################################################################"
	exit 1
else
	echo "###########################################################################################"
	echo "###################################Completed DTR backup.###################################"
	echo "###########################################################################################"
fi

echo "++++++++--------------------------------------------------------------------------------------++++++++"
echo "++++++++--------------------------------------------------------------------------------------++++++++"

echo "##########################################################################################"
echo "###################################Starting DTR(Images) backup.###########################"
echo "##########################################################################################"

echo "Starting DTR(Images) backup, backup will be saved ins backup-dtr-images-${DATE}.tar"

tar -cf backup-dtr-images-${DATE}.tar   $(dirname $(docker volume inspect --format '{{.Mountpoint}}' dtr-registry-${dtr_replica_id}))

if [ "$?" != "0" ]    
then
	echo "##########################################################################################"
	echo "###################################DTR(Images) backup failed.#############################"
	echo "##########################################################################################"
	exit 1
else
	echo "###########################################################################################"
	echo "###################################Completed DTR(Images) backup.###########################"
	echo "###########################################################################################"
fi
 
echo "++++++++--------------------------------------------------------------------------------------++++++++"
echo "++++++++--------------------------------------------------------------------------------------++++++++" 

echo "##########################################################################################"
echo "###################################Starting UCP backup.###################################"
echo "##########################################################################################"


echo "UCP Version is set to $ucp_version"

ucp_id=`docker container run --log-driver none --rm --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp:$ucp_version id`

echo "UCP ID is $ucp_id"

echo "Starting UCP backup, backup will be save in backup-ucp-${DATE}.tar"

docker container run --log-driver none --rm -i \
    --name ucp \
    -v /var/run/docker.sock:/var/run/docker.sock \
    docker/ucp:$ucp_version \
    backup --id  $ucp_id > backup-ucp-${DATE}.tar

if [ "$?" != "0" ]    
then
	echo "##########################################################################################"
	echo "###################################UCP backup failed.#####################################"
	echo "##########################################################################################"
	exit 1
else
	echo "###########################################################################################"
	echo "###################################Completed UCP backup.###################################"
	echo "###########################################################################################"
fi