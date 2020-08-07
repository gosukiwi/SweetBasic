# SweetBasic
AppGameKit's Tier 1 with some sugar on top. Use as much as you want!

An opinionated superset of AGK's Tier 1. It compiles to Tier 1 and in turn to
bytecode with the proprietary compiler from AGK Classic.

It will generate a `main.agc` file in the root directory. You can use it to
manually compile in Studio if needed.

# Features
Most of Tier 1 is implemented with a few exceptions (see below for more info).
Extra features:

## Smarter Assignment
```
# The compiler is smart enough to know what type the variable is when declaring it
name = "Mike"
age = 18
foo = 1.2
name$ = "Mike" # you can still do this if you want

# It also works with types and function return values!
function Person_Create
  p as tPerson
endfunction p

person = Person_Create()
```

## String interpolation
```
name = "Mike"
greeting = "Hello, {name}!"
```

## Comparison / Booleans
Be more expressive with `is`, `isnt`, `true`, `yes`, `on`, `false`, `no` and
`off`!

```
if Switch() is on then DoThis()
// is the same as
if Switch() = 1 then DoThis()
```

## Lambdas / Function Pointers
Define a function with no name and store it in a variable:

```
greeter = function (name as string, age as integer)
  greeting = "Hello {name}! You are {age} years old"
endfunction greeting

// call it
greeting = Call(myFunction, "Thomas", 41) // greeting is now "Hello Thomas! You are 41 years old"

// pass it around, it's just an integer!
function SayHi(greeter as integer, name as string, age as integer)
  greeting = Call(greeter, name, age)
endfunction
```

For more info on how this work, see [Syntax](syntax.md).

## Macros / Generics
Design for this is still in progress.

# Not Implemented
**Goto/Subroutines**: `goto` is bad, blah blah. Just use functions.
**Dim**: There should only be one clear way of declaring arrays. `dim` is
purposely not implemented. With the smarter assignment you won't miss it :)