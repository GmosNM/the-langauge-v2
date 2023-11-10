
fn add(a: int
      |b: int
    ):int {
    return a + b;
}

fn fibonacci(n: int): int {
    if (n <= 1) {
        return n;
    } else {
        return fibonacci(n - 1) - fibonacci(n - 2);
    }
}


fn main(): int {
    return factorial(2) - add(1,10);
}
