# Syntax
**Tentative** syntax. It will take some time to get there, and be more
simplistic at first.

## Literals and Variables
```
a = true // boolean, just 1 internally
a = 1    // integer
a = 1.1  // float
a = "hi" // string
a = [1, 2, 3] // integer[]
a = [1, "foo"] // error, must be all same type

a as integer
a as float
a as string
a as integer[]
```

Variable definitions will be grouped if possible. Defining variables is smarter:

```
a = 1.2
// compiles to
a as float
a = 1.2

a = SomeFunc() // assume this returns SomeType
// compiles to
a as SomeType
a = SomeFunc()
```

## Globals and Constants

```
global a = 1
constant a = 1 // RHS must be literal
```

## Types
```
type Person
  name as string
  age as integer
  likes as string = "Cats"
endtype

// types automatically generate a `create` function which is aware of default values
person = CreatePerson("Federico", 30)

// compiles to
type Person
  name as string
  age as integer
  likes as string
endtype

function CreatePerson(name as string, age as integer, likes as string)
  person as Person
  person.name = name
  person.age = age
  person.likes = likes
endfunction

CreatePerson("Federico", 30, "Cats") // NOTE: Default value was inserted here

person as Person
person.name = "Federico"
person.age = 30
person.likes = "Cats"
```

## Functions
```
function foo(arg1 = "default value 1", arg2 = bar())
  if true then DoSomething()
endfunction

foo()

// compiles to

function foo(arg1 as string)
  if true then DoSomething()
endfunction

foo("default value 1", bar())
```

## Lambdas
Anonymous functions you can pass around. They are __not closures__, they don't
wrap over the internal state. All functions in Tier 1 must be defined in the
global scope, so they must be "pulled out" if they are defined inside a
function.

The way it works is, lambdas are an expression, and get compiled to an integer,
an index/pointer to the actual lambda, which lives at the very top of the file
in a global context.

```
func = function (name as string, age as integer, foo as SomeType)
  // ...
endfunction

Call(func, "Foo", 11, CreateSomeType(...))

// compiles to
INTERNAL__LAMBDAS_NAMES as string[]
INTERNAL__LAMBDAS_PARAMS_STRINGS as string[]    // stacks of params
INTERNAL__LAMBDAS_PARAMS_INTEGERS as integer[]
INTERNAL__LAMBDAS_PARAMS_SomeType as SomeType[]

function INTERNAL__CALL_LAMBDA(index)
  if index = 1
    INTERNAL__LAMBDA1()
  else
    Log("...")
    Message("Could not find lambda ... etc")
    end
  endif
endfunction

function INTERNAL__LAMBDA1()
  // check if argument exist
  if INTERNAL__LAMBDAS_PARAMS_STRINGS.length = -1
    Log("Could not ...")
    Message("Could not ...")
    end
  endif
  name as string
  name = INTERNAL__LAMBDAS_PARAMS_STRINGS[INTERNAL__LAMBDAS_PARAMS_STRINGS.length]
  INTERNAL__LAMBDAS_PARAMS_STRINGS.delete(INTERNAL__LAMBDAS_PARAMS_STRINGS.length)
  // same for integer and sometype

  // ... body of function here
endfunction

func = 1 // NOTE: The lambda itself was compiled to an integer, it's internals moved up
INTERNAL__LAMBDAS_PARAMS_STRINGS.insert("Foo")
INTERNAL__LAMBDAS_PARAMS_INTEGERS.insert(11)
INTERNAL__LAMBDAS_PARAMS_SomeType.insert(CreateSomeType(...))
INTERNAL__CALL_LAMBDA(func)
```

Pass as parameter and return it from function

```
function foo(callback as integer)
  somevar = callback // somevar is now a pointer/index to a lambda, starting at 1 (or 0, not sure yet)
endfunction somevar
```

Call it from inside a function:

```
function foo(callback as integer)
  Call(callback, param1, param2, ...)
endfunction somevar
```

### Nested lambdas
You can define lambdas inside functions/lambdas, they will be moved to the
global scope:

```
function foo()
  bar = function()
  endfunction
endfunction bar

// compiles to
// LAMBDA GENERATION CODE HERE
function INTERNAL__LAMBDA1()
endfunction

function foo()
  bar = 1
endfunction
```

## Generics/Macros (MAYBE)
A macro is executed at compile-time and inlines whatever it defines.

When inside macros, you can use `any` as a placeholder for a type. Note that all
instances of `any` must be of the same type. Only one allowed at the moment.

```
// Macros simply inline the content when they are used
macro map(items as any[], cb as integer)
  result as any[]
  for i = 0 to items.length - 1
    result.insert(Call(cb, items[i]))
  next i
endmacro result

doubles = map([1, 2, 3], function (num as integer)
  double = num * num
endfunction double)

res = map(["a", "b", "c"], function (str as string)
  concat = str + str
endfunction concat)

// compiles to
// ... Lambda definition

// TODO: Maybe all this could live in a self-executed lambda
dim _items[3] as integer = [1, 2, 3]
_cb = 2 // some lambda index
result as integer[]
for i = 0 to _items.length
  result.insert(Call(_cb, _items[i]))
next i
doubles = result

// same for strings
```

## Polymorphism
TODO: See if we can use macros to do some kind of polymorphism

## List Comprehension

```
a = i for i in [1, 2, 3] when i % 2 is 0
```

## Better Types

```
type Person
  name as string
  age as integer
endtype

GetTypeFields("Person") # => ["name", "age"] # this could be done just by auto-generating many helper functions with each type

p as Person
p.name = "Fede"
p.age = 30
PersonGet(p, "name") # => "Fede" # this could be done just by auto-generating many helper functions with each type
PersonSet(p, "name", "A wizard") # not sure if this is possible, maybe with macros later on in development
```

## Standard Library
Provides a few quality of life improvements by adding a standard library:

```
// collections
each()
each#()
each$()
map()
reduce()
find()
```
