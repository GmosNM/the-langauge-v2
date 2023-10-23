


fn fizzBuzz(): void {
    for (0..) |i| {
        if (i % 3 == 0 and i % 5 == 0) {
            println("FizzBuzz");
        } else if (i % 3 == 0) {
            println("Fizz");
        } else if (i % 5 == 0) {
            println("Buzz");
        } else {
            println("%d", i);
        }
    }
}
