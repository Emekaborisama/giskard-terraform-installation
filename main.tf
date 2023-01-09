
#read file to get vpc id and pem key
locals {
  data = jsondecode(file("bash_output.json"))
  pem_key = local.data.keypair
}
output "pemkey" {
    value=local.pem_key
  
}



#connect aws 

provider "aws" {
    shared_credentials_file = "~/.aws/credentials"
    region = "us-east-1"
  
 }

 #connect to an existing VPC
resource "aws_vpc" "main" {
    cidr_block = "172.16.0.0/16"
    enable_dns_hostnames = true 
    tags= {
        Name = "main"
    }
  
}


#setup internet gateway for the public subnet 
resource "aws_internet_gateway" "public_subnet3_ig" {
    vpc_id = aws_vpc.main.id
    tags = {
        "Name" = "public_subnet3_ig"
    }
  
}


#setup route table for the internet gate way
resource "aws_route_table" "public_subnet3_RT" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block="0.0.0.0/0"
        gateway_id = aws_internet_gateway.public_subnet3_ig.id
        }
    route {
        ipv6_cidr_block="::/0"
        gateway_id = aws_internet_gateway.public_subnet3_ig.id
    }
    tags ={
        Name="public_subnet3_RT"
    }
  
}


#route table association
resource "aws_route_table_association" "public_subnet3_rt_a" {
    subnet_id = aws_subnet.public_subnet3.id
    route_table_id = aws_route_table.public_subnet3_RT.id

  
}

#security group creation. for the ec2
resource "aws_security_group" "giskard_terraform_sg" {
    name = "giskard_terraform_sg"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_subnet" "public_subnet3"{
    cidr_block = "172.16.140.0/24"
    availability_zone = "us-east-1c"
    vpc_id = aws_vpc.main.id
    
    tags = {
      "Name" = "publicsubnet"
    }
}






resource "aws_instance" "giskard_terraform" {
    ami = "ami-0a6b2839d44d781b2"
    instance_type = "t3.small"
    vpc_security_group_ids = [aws_security_group.giskard_terraform_sg.id]
    ebs_block_device {
        device_name = "/dev/sda1"
        volume_size = 100
        volume_type= "gp2"
        delete_on_termination = true
    }
    key_name = "yes-6"
    subnet_id = aws_subnet.public_subnet3.id
    associate_public_ip_address = true
    ebs_optimized = true
    user_data = <<EOF
        !# /bin/bash
        sudo yum update
        sudo yum install docker
        wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) 
        sudo mv docker-compose-$(uname -s)-$(uname -m) /usr/local/bin/docker-compose
        sudo chmod -v +x /usr/local/bin/docker-compose
        sudo systemctl enable docker.service
        sudo systemctl start docker.service
        sudo usermod -a -G docker ec2-user
        id ec2-user
        newgrp docker
        sudo yum install python3-pip
        sudo pip3 install docker-compose
        sudo yum install git
        git clone https://github.com/Giskard-AI/giskard.git
        cd giskard
        docker-compose up -d
    EOF

    
    tags = {
      "Name" = "giskard_ec2"
    }
  
}


# resource "aws_ebs_volume" "ebsvolume_giskard" {
    
#     availability_zone = "us-east-1c"
#     size = 80
#     tags ={
#         Name="giskardEBS"
#     }

  
# }

# resource "aws_volume_attachment" "eb_att_giskard" {
#     device_name="/dev/xvda"
#     volume_id = aws_ebs_volume.ebsvolume_giskard.id
#     instance_id = aws_instance.giskard_terraform.id
# }

