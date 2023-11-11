
##TODOS

- [ ] make the parser a bool type so we can handel errors


evrey variable should have a current label name in the struct so in the code gen we can compare the label name
with the current label name and insert the correct code for the label

let x: int = 10; // global lable < _start
x = 20; // global lable < _start

fn main(): int {
    let x: int = 10; // lable < main
    x = 20; // lable < main
}


all of this is just me trying to do something new
