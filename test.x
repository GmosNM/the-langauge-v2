


let x: []int = [];

x << 10;
x << 1;

for (x) |i|{
    # should be 10\n 1
    println(i);
}
