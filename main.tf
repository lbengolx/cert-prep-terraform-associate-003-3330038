resource "aws_instance" "Lore_INS" {
    #instance configuration
    ami = "ami-05c3dc660cb6907f0"
    instance_type = "t2.micro"
}
