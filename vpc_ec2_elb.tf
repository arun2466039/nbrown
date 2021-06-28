provider "aws" {
       region = var.aws_region
}

##VPC
resource "aws_vpc"  nbg_terra_vpc {
          cidr_block = var.vpc_cidr
          tags = {
             Name = "NBG_VPC"
          }   
}

## Internet Gateway
resource "aws_internet_gateway" "nbg_igw" {
          vpc_id = "${aws_vpc.nbg_terra_vpc.id}"
          tags = {
            Name = "NBG_Main_IGW"
          }               
}

#subnets: Public
resource "aws_subnet" "public" {
          count = "${length(var.subnets_cidr)}" 
          vpc_id = "${aws_vpc.nbg_terra_vpc.id}"
          cidr_block = "${element(var.subnets_cidr, count.index)}"
          availability_zone = "${element(var.azs, count.index)}"
          map_public_ip_on_launch = true
          tags = {
             Name = "NBG_Subnet-${count.index+1}"
          }
}

## Route table: Attach internet gateway
resource "aws_route_table" "public_rt" {
          vpc_id = "${aws_vpc.nbg_terra_vpc.id}"
          route {
             cidr_block = "0.0.0.0/0"
             gateway_id = "${aws_internet_gateway.nbg_igw.id}"
          }
          tags = {
            Name = "NBG_PublicRouteTable"
          }
}

#Route Table assosication with public subnets
resource "aws_route_table_association" "rta" {
         count = "${length(var.subnets_cidr)}"
         subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
         route_table_id = "${aws_route_table.public_rt.id}"
}
#Security Group 
resource "aws_security_group" NBG_Sec_group_webservers {
      name = "allow_http"
      description = "Allow http inbound traffic"
      vpc_id = "${aws_vpc.nbg_terra_vpc.id}"
      
      ingress {
          from_port = 80
          to_port   = 80
          protocol  = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
      }
       ingress {
          from_port = 22
          to_port   = 22
          protocol  = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
      }
              
        egress {
           from_port = 0
           to_port   = 0
           protocol = "-1"
           cidr_blocks = ["0.0.0.0/0"]
           }
}

## EC2 Instances ##############

resource "aws_instance" NBG_Webservers {
          count = var.number_instances
          ami = var.amiid
          instance_type = var.instance_type
          security_groups = ["${aws_security_group.NBG_Sec_group_webservers.id}"]
          subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
          user_data = "${file("install_httpd.sh")}"
          key_name = var.key
          tags = {
             Name = "NBG_web_servers-062021_${count.index}"    
             }
}             

## ELB Creation #################

resource "aws_elb" nbrowngroup {
       name = "nbrowngroup"
       subnets = "${aws_subnet.public.*.id}"
       security_groups = ["${aws_security_group.NBG_Sec_group_webservers.id}"]    
       
       listener {
          instance_port  = 80
          instance_protocol = "http"
          lb_port    = 80
          lb_protocol = "http"
      }
      
      health_check  {
         healthy_threshold  = 2
         unhealthy_threshold = 2
         timeout = 3
         target  =  "HTTP:80/index.html"
         interval   =30
         }
         
      instances   = "${aws_instance.NBG_Webservers.*.id}"
      cross_zone_load_balancing  = true
      idle_timeout   =100
      connection_draining = true
      connection_draining_timeout = 300
      
      tags = {
        Name = "nbrowngroup-elb"
        }
 }
output "NBROWN_Loadbalancer_DNS_name" {
   value = "${aws_elb.nbrowngroup.dns_name}"
}
