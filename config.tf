provider "aws" {
  region = "us-east-2"
  shared_credentials_file = "~/.aws/credentials"
}

resource "aws_key_pair" "awv_key" {
  key_name   = "awv_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCOhJUqYHQ3ibEV2An3Uv7eUMw7kLIkYWoHGjvDufPlH+ApPZi2QklyvqDVyVWVFOzTNXhHw0PTBFiYf8MA4S8U32YiYfWJa2LwVrqSBC8dCHhbBUHEk1pn7Qr+ygMP4v9Y66dBb0nIb8TEDD5DkEC+QZ9IrXDbAQDd4tBMXMkb7N3EPfr8eMoVuT6yzPYe+d3rz1zLQrZzDdsHHuEQF68S93uLZzfX0Ov3D4kSTqLsav3eQKKo5usFNBQcDp0O+nEX2e1RFx6bf6TioYG381jJX/8dszbtw1C2ZODuVjJZ6KCFvpeacGGUYdeqVpQtyd6yBFWYz0gkoZrRTshlFL31 imported-openssh-key"
}

variable "aws-id" {}
variable "aws-sec" {}

resource "aws_security_group" "test_group_terra" {
  name        = "terra_test"
  vpc_id      = "vpc-78a40913"

  ingress {
    description = "open https inbound all"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "open ssh inbound all"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "builder" {
  ami = "ami-0e82959d4ed12de3f"
  instance_type = "t2.micro"
  key_name = "awv_key"
  vpc_security_group_ids = ["${aws_security_group.test_group_terra.id}"]

#  provisioner "file" {
#    source = "~/.aws/credentials"
#    destination = "~/.aws/credentials"

#    connection {
#      type = "ssh"
#      user = "ubuntu"
#      private_key = "${file("~/.ssh/id_rsa")}"
#      agent = "false"
#  }
#  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install -y default-jdk maven awscli",
      "git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git",
      "cd boxfuse-sample-java-war-hello && mvn package",
#      "export AWS_ACCESS_KEY_ID= "${var.aws-id}" && export AWS_SECRET_ACCESS_KEY= "${var.aws-sec}" && 
#      "export AWS_DEFAULT_REGION=us-east-2",
       "aws configure set aws_access_key_id ${var.aws-id}",
       "aws configure set aws_secret_access_key ${var.aws-sec}",
       "aws configure set default.region us-east-2",
       "aws s3 cp target/hello-1.0.war s3://zloben.test.ru"  
    ]
  }
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "${file("~/.ssh/id_rsa")}"
    agent = "false"
  }
}

resource "aws_instance" "tomcat" {
  ami = "ami-0e82959d4ed12de3f"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.awv_key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.test_group_terra.id}"]

#  provisioner "file" {
#    source = "~/.aws/credentials"
#    destination = "~/.aws/credentials"
#  }
#  connection {
#    type = "ssh"
#    user = "ubuntu"
#    private_key = "${file("~/.ssh/id_rsa")}"
#    agent = "false"
# }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install -y default-jdk tomcat8 awscli",
#      "export AWS_ACCESS_KEY_ID= "${var.aws-id}" && export AWS_SECRET_ACCESS_KEY= "${var.aws-sec}" && 
#      "export AWS_DEFAULT_REGION=us-east-2",
      "aws configure set aws_access_key_id ${var.aws-id}",
      "aws configure set aws_secret_access_key ${var.aws-sec}",
      "aws configure set default.region us-east-2",
      "aws s3 cp s3://zloben.test.ru/hello-1.0.war /tmp/hello-1.0.war",
      "sudo mv /tmp/hello-1.0.war /var/lib/tomcat8/webapps/hello-1.0.war",
      "sudo systemctl restart tomcat8"
    ]
  }
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "${file("~/.ssh/id_rsa")}"
    agent = "false"
  }
}