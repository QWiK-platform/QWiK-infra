# -- Internet Gateway
resource "aws_internet_gateway" "this" {
    vpc_id = aws_vpc.this.id

    tags = merge(
        var.tags,
        {
            Name = "${var.project_name}-igw"
        }
    )
}

# -- NAT Gateways
resource "aws_eip" "this" {
    domain = "vpc"

    tags = merge(
        var.tags,
        {
            Name = "${var.project_name}-nat-eip"
        }
    )

    depends_on = [
        aws_internet_gateway.this
    ]
}

resource "aws_nat_gateway" "this" {
    allocation_id = aws_eip.this.id
    subnet_id     = aws_subnet.public[0].id

    tags = merge(
        var.tags,
        {
            Name = "${var.project_name}-regional-nat"
        }
    )

    depends_on = [
        aws_internet_gateway.this
    ]
}