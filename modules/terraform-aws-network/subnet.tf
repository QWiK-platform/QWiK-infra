# -- Public Sunbet
resource "aws_subnet" "public" {
    count = length(var.public_subnet_cidrs)

    vpc_id = aws_vpc.this.id
    cidr_block = var.public_subnet_cidrs[count.index]
    availability_zone = var.azs[count.index]

    tags = merge(
        var.tags,
        {
            Name = "${var.project_name}-subnet-public-${count.index + 1}"
        }
    )
}

# -- Private Subnet
resource "aws_subnet" "private" {
    count = length(var.private_subnet_cidrs)

    vpc_id = aws_vpc.this.id
    cidr_block = var.private_subnet_cidrs[count.index]
    availability_zone = var.azs[count.index % length(var.azs)]

    tags = merge(
        var.tags,
        {
            Name = "${var.project_name}-subnet-private-${count.index + 1}"
        }
    )
}