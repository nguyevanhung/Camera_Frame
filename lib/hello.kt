
fun main() {
    
    val in2: () -> Unit = {
        println("hello")
    }

    in2()

    val square : (Int) -> Int = {
    x -> x * x        
    }

    println(square(4))
}