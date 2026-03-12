# -- Public Subnet Route Table
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.this.id

    route {
        cidr_block = var.all_cidr
        gateway_id = aws_internet_gateway.this.id
    }

    tags = merge(
        var.tags,
        {
            Name = "${var.project_name}-public-rt"
        }
    )
}

# -- Private Subnet Route Table
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.this.id

    route {
        cidr_block = var.all_cidr
        nat_gateway_id = aws_nat_gateway.this.id
    }

    tags = merge(
        var.tags,
        {
            Name = "${var.project_name}-private-rt"
        }
    )
}

# -- Public Subnet Route Table Associations
resource "aws_route_table_association" "public" {
    count = length(var.public_subnet_cidrs)

    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}

# -- Private Subnet Route Table Associations
resource "aws_route_table_association" "private" {
    count = length(var.private_subnet_cidrs)

    subnet_id = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private.id
}