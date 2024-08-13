 resource "aws_instance" "ec2-instance1" {
   ami = "ami-05c3dc660cb6907f0"
   instance_type = "t2.micro"

   tags = {                                
     Name = "Lore-server1"
}
}


resource "aws_instance" "ec2-Instance2" {
  provider      = aws.virginia
  ami           = "ami-0ae8f15ae66fe8cda"  # AMI for us-west-1
  instance_type = "t2.micro"

  tags = {                                
    Name = "lore-server2"
}
}