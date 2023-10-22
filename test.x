const PI: float = 3.141592653589793;
const counter: int = 0;

pub fn factorial(n: int): int {
    const result: int = 1;
    if (n <= 1){
        return 1;
    }else {
        while n > 1 {
            const temp: int = result * n;
            result = temp;
            n -= 1;
        }
        return result;
    }
}

const colors: [3]string = ["Red", "Green", "Blue"];
fn main() void {
    const i: int = 0;
    while (i < 3) {
        const color: string = colors[i];
        print("Color {}: {}\n", i, color);
        i += 1;
    }
}

