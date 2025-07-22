for i in $(seq 1 1 60)
    do 
        echo da-training-cluster-$i
        aws cloudformation describe-stacks --stack-name da-training-cluster-$i  --query "Stacks[*].Outputs[?OutputKey=='HeadNodePrivateIP'].OutputValue" --output text
        echo " "
    done
