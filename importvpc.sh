#! /bin/bash

#generate random set of number for the keypair value
randomnum=$(jot -r 1 0 $Na)



#ask to import vpc
echo would you love to import a vpc yes or no
read h
if [ $h == "yes" ]
then
#get the vpc id
echo input your vpc id 
read y
terraform import aws_vpc.main $y
#vpc-03ae9d4027b89a419
elif [ $h == "no" ]
then
echo pass
fi


 
echo would you love to import a subnet yes or no
#subnet-00b393fddf7424836
read e
if [ $e == "yes" ]
then
echo input your subnet id?
read f
terraform import aws_subnet.public_subnet $f
elif [ $e == "no" ]
then
echo pass
fi





echo Do you want to create a key pair? 
#'if yes type yes else if you already have a key pair then type no and input the path'
read b
if [ $b == "yes" ]
then

# aws ec2 create-key-pair --key-name $b-$randomnum --query 'KeyMaterial' --output text > ~/Downloads/$b-$randomnum.pem
aws ec2 create-key-pair --key-name $b-$randomnum --query 'KeyMaterial' --output text > $b-$randomnum.pem
chmod 400  $b-$randomnum.pem
pem_file=$b-$randomnum
elif [ $b == "no" ]
then
echo key pair file path with the pem file e.g /user/hp/downlaods/b
read c
pem_file=$c
fi


#store key pair and vpc id in a json format

cat <<EOF > bash_output.json
{"vpc_id": "$a", "keypair":"$pem_file"}
EOF


#run terraform init,apply and plan
terraform init
terraform apply
terraform plan


# terraform destroy -target aws_internet_gateway.public_subnet3_ig -target aws_route_table.public_subnet3_RT -target aws_security_group.giskard_terraform_sg -target aws_subnet.public_subnet -target aws_instance.giskard_terraform -target aws_route_table_association.public_subnet3_rt_a -target aws_subnet.public_subnet3