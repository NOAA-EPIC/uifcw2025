for i in $(seq 1 1 60)
    do 
        #pcluster create-cluster --region us-east-1 --cluster-name da-training-cluster-$i --cluster-configuration da_hpc.yaml --rollback-on-failure false --debug
        pcluster delete-cluster --region us-east-1 --cluster-name da-training-cluster-$i 
    done
