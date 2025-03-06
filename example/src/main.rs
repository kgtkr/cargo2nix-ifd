use rand::prelude::*;

fn main() {
    println!("Hello, world!");
    let mut rng = rand::rng();
    for _ in 0..10 {
        println!("Random number: {}", rng.gen::<u32>());
    }
}
