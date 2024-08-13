 resource "aws_instance" "ec2-instance1" {
   ami = "ami-05c3dc660cb6907f0"
   instance_type = "t2.micro"

   tags = {                                
     Name = "Lore-server1"
}
}


resource "aws_instance" "ec2-Instance2" {
  provider      = aws.west
  ami           = "ami-03972092c42e8c0ca"  # AMI for us-west-1
  instance_type = "t2.micro"

  tags = {                                
    Name = "lore-server2"
}
}