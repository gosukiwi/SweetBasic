Program
  = stmts:Top_Level_Statement* { return { type: 'PROGRAM', stmts } }

Top_Level_Statement // These can only live at the top-level (eg: not inside a function)
  = _ stmt:Function_Definition _ { return stmt }
  / _ stmt:Type_Definition _     { return stmt }
  / _ stmt:Import_Plugin _       { return stmt }
  / Statement
  / Comment

Comment
  = "/*" (!"*/" .)* "*/"                  { return { type: 'COMMENT' } }
  / "remstart"i (!"remend"i .)* "remend"i { return { type: 'COMMENT' } }
  / "//" [^\n]*                           { return { type: 'COMMENT' } }
  / "`" [^\n]*                            { return { type: 'COMMENT' } }
  / "rem"i ws [^\n]*                      { return { type: 'COMMENT' } }

Statement
  = stmt:Line_Statement ":" multi:Statement { return { type: 'MULTILINE_STATEMENT', stmts: [stmt].concat(multi) } }
  / Line_Statement

Line_Statement
  = _ stmt:Assignment _             { return stmt }
  / _ stmt:If_Statement _           { return stmt }
  / _ stmt:For_Statement _          { return stmt }
  / _ stmt:Select_Statement _       { return stmt }
  / _ stmt:Do_Loop_Statement _      { return stmt }
  / _ stmt:While_Statement _        { return stmt }
  / _ stmt:Repeat_Until_Statement _ { return stmt }
  / _ stmt:Inc_Dec_Statement _      { return stmt }
  / _ stmt:Function_Call _          { return stmt }
  / _ stmt:Dot_Call _               { return stmt }
  / _ stmt:Dot_Assign _             { return stmt }
  / _ stmt:Flag_Statement _         { return stmt }
  / _ stmt:Dim_Statement _          { return stmt }
  / _ stmt:Keyword                  { return stmt }

Keyword
  = "exitfunction"i _ { return { type: 'KEYWORD', value: 'exitfunction' } }
  / "end"i ws         { return { type: 'KEYWORD', value: 'end' } }
  / "continue"i _     { return { type: 'KEYWORD', value: 'continue' } }

// IMPORT PLUGIN
// =====================================================================================================================
Import_Alias
  = ws "as"i ws alias:Identifier { return alias.value }

Import_Plugin
  = "#import_plugin"i ws plugin:Identifier alias:Import_Alias?
    { return { type: 'PLUGIN_IMPORT', plugin: plugin.value, alias } }

// TYPE DEFINITION
// =====================================================================================================================
Type_Variable_Definition
  = name:Identifier _ "as"i _ as:Identifier array:Assignment_Array_Braces? _
    { return { type: 'FIELD_DEFINITION', name, as, array } }

Type_Definition
  = "type"i ws name:Identifier ws fields:Type_Variable_Definition* _ "endtype"i
    { return { type: 'TYPE_DEFINITION', name, fields } }

// ASSIGNMENT
// =====================================================================================================================
Assignment_Arrray_Index
  = Identifier
  / Integer

Assignment_Array_Numbers
  = num:Assignment_Arrray_Index _ "," _ nums:Assignment_Array_Numbers { return [num].concat(nums) }
  / num:Assignment_Arrray_Index { return num }

Assignment_Array_Braces
  = _ "[" _ nums:Assignment_Array_Numbers _ "]" { return [].concat(nums) }
  / _ "[]" { return [] }

Variable_Definition
  = g:("global"i ws)? name:Identifier ws "as"i ws as:Identifier array:Assignment_Array_Braces?
    { return { type: 'VARIABLE_DEFINITION', name, as, global: !!g, array } }

Assignment
  = name:Identifier ws "as"i ws as:Identifier _ "[" _ len:Integer _ "]" _ "=" _ value:Dim_Inline_Array
    { return { type: 'DIM_ASSIGN', name, len, as: as.value, values: value } }
  / g:("global"i ws)? lhs:Identifier ws "as"i ws as:Identifier _ "=" _ rhs:Expression
    { return { type: 'ASSIGNMENT', lhs, rhs, as: as.value, global: !!g } }
  / g:("global"i ws)? lhs:Array_Identifier _ "=" _ rhs:Expression
    { return { type: 'ASSIGNMENT', lhs, rhs, as: null, global: !!g } }
  / Variable_Definition

// FUNCTION DEFINITION
// =====================================================================================================================
Parameter_Array_Braces
  = _ braces:"[]"+ { return braces.length }

Parameter
  = name:Identifier ref:(ws "ref")? ws "as"i ws as:Identifier array:Parameter_Array_Braces?
    { return { type: 'PARAMETER', name: name.value, as: as.value, ref: !!ref, array: +array } }
  / name:Identifier
    { return { type: 'PARAMETER', name: name.value, as: 'INTEGER', ref: false, array: 0 } }

Parameter_List
  = param:Parameter _ "," _ list:Parameter_List { return { type: 'PARAMETER_LIST', params: [param].concat(list.params) } }
  / param:Parameter                             { return { type: 'PARAMETER_LIST', params: [param] } }

Function_Definition
  = "function"i ws name:Identifier _ "(" _ args:Parameter_List? _ ")" _
    body:Statement*
    "endfunction"i _ ret:Expression?
    { return { type: 'FUNCTION_DEFINITION', name: name.value, args, body, ret } }

// FUNCTION CALL
// =====================================================================================================================
Argument_List
  = arg:Expression _ "," _ list:Argument_List { return { type: 'ARGUMENT_LIST', args: [arg].concat(list.args) } }
  / arg:Expression                            { return { type: 'ARGUMENT_LIST', args: [arg] } }

Function_Call
  = name:Identifier _ "(" _ args:Argument_List? _ ")" { return { type: 'FUNCTION_CALL', name: name.value, args } }

// FOR STATEMENT
// =====================================================================================================================
For_Step
  = "step"i ws step:Integer _ { return step }

For_Statement
  = "for"i ws from:Assignment ws "to"i _ to:Expression _ step:For_Step?
    body:Statement*
    "next"i _ next:Identifier
    { return { type: 'FOR_STATEMENT', from, to, step, body, next } }

// IF STATEMENT
// =====================================================================================================================
If_Header
  = "if"i ws condition:Expression _ body:Statement* { return { condition, body } }

Else_If
  = "elseif"i ws condition:Expression _ body:Statement* elseif:Else_If
    { return { type: 'ELSEIF', condition, body, elseif } }
  / Else

Else
  = "else"i _ body:Statement* "endif"i { return { type: 'ELSE', body } }
  / "endif"i { return { type: 'ENDIF' } }

If_Statement
  = "if"i ws condition:Expression ws "then"i ws body:Statement
    { return { type: "IF_STATEMENT", condition, body: [body], otherwise: { type: "ENDIF" } } }
  / header:If_Header otherwise:Else_If
    { return { type: "IF_STATEMENT", condition: header.condition, body: header.body, otherwise } }

// SELECT STATEMENT
// =====================================================================================================================
Case_Statement
  = "case"i ws "default"i _ ":"? body:Statement* "endcase"i _ { return { type: 'CASE', condition: 'DEFAULT', body } }
  /"case"i ws condition:Expression _ ":"? body:Statement* "endcase"i _ { return { type: 'CASE', condition, body } }

Select_Statement
  = "select"i ws variable:Identifier _ cases:Case_Statement+ _ "endselect"i { return { type: 'SELECT', cases } }

// DIM STATEMENT
// =====================================================================================================================
// About DIM ASSIGN: It can only have a default value when it has only 1 dimension
Primitive_List
  = p:Primitive _ "," _ l:Primitive_List { return [p].concat(l) }
  / p:Primitive { return [p] }

Primitive
  = Number
  / String

Dim_Inline_Array
  = "[" _ list:Primitive_List _ "]" { return list }

Dim_Statement
  = "dim"i ws name:Identifier _ "[" _ len:Integer? _ "]" _ "as"i ws as:Identifier _ "=" _ value:Dim_Inline_Array
    { return { type: 'DIM_ASSIGN', name, len, as: as.value, values: value } }
  / "dim"i ws name:Identifier _ array:Assignment_Array_Braces _ "as"i ws as:Identifier
    { return { type: 'DIM', name, array, as: as.value } }

// OTHER STATEMENTS
// =====================================================================================================================
Do_Loop_Statement
  = "do"i body:Statement* "loop"i { return { type: 'DO_LOOP', body } }

Repeat_Until_Statement
  = "repeat"i body:Statement* "until"i _ condition:Expression { return { type: 'REPEAT_UNTIL', body, condition } }

While_Statement
  = "while"i _ condition:Expression _ body:Statement* "endwhile"i { return { type: 'WHILE', condition, body } }

Inc_Dec_Statement
  = "inc"i ws expr:Expression { return { type: 'INC', expr } }
  / "dec"i ws expr:Expression { return { type: 'INC', expr } }

Flag_Statement
  = "#include" ws file:String { return { type: 'INCLUDE', file } }
  / "#insert" ws file:String { return { type: 'INSERT', file } }
  / "#constant" ws name:Identifier ws value:Expression { return { type: 'CONSTANT', name, value } }
  / "#option_explicit" { return { type: 'OPTION_EXPLICIT'  } }
  / "#company_name" ws name:String { return { type: 'COMPANY_NAME', name } }

Dot_Call
  = receiver:Array_Identifier _ "." _ message:Function_Call
    { return { type: 'DOT_CALL', receiver, message: message.name, args: message.args } }

Dot_Assign
  = receiver:Array_Identifier _ "." _ field:Identifier _ "=" _ rhs:Expression
    { return { type: 'DOT_ASSIGN', receiver, field: field.value, rhs } }

// EXPRESSIONS
// =====================================================================================================================
Expression
  = Binop_Boolean

Binop_Boolean
  = lhs:Binop_Comparison _ "and"i _ rhs:Binop_Boolean    { return { type: 'BINOP', operator: 'AND', lhs, rhs } }
  / lhs:Binop_Comparison _ "or"i _ rhs:Binop_Boolean     { return { type: 'BINOP', operator: 'OR', lhs, rhs } }
  / Binop_Comparison

Binop_Comparison
  = lhs:Binop_Addition _ "<>" _ rhs:Binop_Comparison     { return { type: 'BINOP', operator: 'NEQ', lhs, rhs } }
  / lhs:Binop_Addition _ "isnt"i _ rhs:Binop_Comparison   { return { type: 'BINOP', operator: 'NEQ', lhs, rhs } }
  / lhs:Binop_Addition _ "=" "="? _ rhs:Binop_Comparison { return { type: 'BINOP', operator: 'EQ', lhs, rhs } }
  / lhs:Binop_Addition _ "is"i _ rhs:Binop_Comparison     { return { type: 'BINOP', operator: 'EQ', lhs, rhs } }
  / lhs:Binop_Addition _ ">=" _ rhs:Binop_Comparison     { return { type: 'BINOP', operator: 'GTEQ', lhs, rhs } }
  / lhs:Binop_Addition _ "<=" _ rhs:Binop_Comparison     { return { type: 'BINOP', operator: 'LTEQ', lhs, rhs } }
  / lhs:Binop_Addition _ ">" _ rhs:Binop_Comparison      { return { type: 'BINOP', operator: 'GT', lhs, rhs } }
  / lhs:Binop_Addition _ "<" _ rhs:Binop_Comparison      { return { type: 'BINOP', operator: 'LT', lhs, rhs } }
  / Binop_Addition

Binop_Addition
  = lhs:Binop_Mult _ "-" _ rhs:Binop_Addition { return { type: 'BINOP', operation: 'MINUS', lhs, rhs } }
  / lhs:Binop_Mult _ "+" _ rhs:Binop_Addition { return { type: 'BINOP', operation: 'PLUS', lhs, rhs } }
  / Binop_Mult

Binop_Mult
  = lhs:Unary_Expression  _ "*" _ rhs:Binop_Mult { return { type: 'BINOP', operation: 'TIMES', lhs, rhs } }
  / lhs:Unary_Expression  _ "/" _ rhs:Binop_Mult { return { type: 'BINOP', operation: 'DIV', lhs, rhs } }
  / lhs:Unary_Expression  _ "%" _ rhs:Binop_Mult { return { type: 'BINOP', operation: 'MOD', lhs, rhs } }
  / Unary_Expression

Unary_Expression
  = 'not'i _ expr:Expression { return { type: 'UNARY', operator: 'NOT', value: expr } }
  / '-' _ expr:Expression { return { type: 'UNARY', operator: 'MINUS', value: expr } }
  / Literal

// LITERALS
// =====================================================================================================================
Literal
  = "(" _ expr:Expression _ ")" { return expr }
  // Closure
  / Dot_Call
  / Function_Call
  / String
  / Number
  / Boolean
  / Array_Identifier

// ARRAY IDENTIFIER
// =====================================================================================================================
ArrayIdentifier_Braces
  = _ "[" _ nums:Assignment_Array_Numbers _ "]" { return [].concat(nums) }

Array_Identifier
  = identifier:Identifier index:ArrayIdentifier_Braces { return { type: 'ARRAY_ACCESS', identifier, index } }
  / Identifier

// REMAINING LITERALS
// =====================================================================================================================
String
  = '""'                     { return { type: 'STRING', value: "" }    }
  / '"' chars:Characters '"' { return { type: 'STRING', value: chars } }

Characters
  = Characters:Single_Character+ { return Characters.join(""); }

Single_Character // any unicode character except " or \ or control character
  = [^"\\\0-\x1F\x7f]
  / '\\"'  { return '"';  }
  / "\\\\" { return "\\"; }
  / "\\/"  { return "/";  }
  / "\\b"  { return "\b"; }
  / "\\f"  { return "\f"; }
  / "\\n"  { return "\n"; }
  / "\n"   { return "\n"; }
  / "\\r"  { return "\r"; }
  / "\\t"  { return "\t"; }

Identifier
  = [a-zA-Z][a-zA-Z0-9-_#$]* { return { type: 'IDENTIFIER', value: text() } }

Number
  = Float
  / Integer

Float
  = "." t:[0-9]+          { return { type: 'FLOAT', value: parseFloat('0.' + t.join('')) } }
  / h:[0-9]+ "." t:[0-9]+ { return { type: 'FLOAT', value: parseFloat(h.join('') + '.' + t.join('')) } }

Integer
  = Octal
  / Hexadecimal
  / Binary
  / [0-9]+ { return { type: 'INTEGER', value: parseInt(text(), 10) } }

Binary
  = "%" num:[01]+ { return { type: 'BINARY_INTEGER', value: num.join('') } }

Octal
  = "0c" num:[0-7]+ { return { type: 'OCTAL_INTEGER', value: num.join('') } }

Hexadecimal
  = "0x" num:[0-9A-F]+ { return { type: 'HEXADECIMAL_INTEGER', value: num.join('') } }

Boolean
  = "true"i  { return { type: 'BOOLEAN', value: true } }
  / "yes"i   { return { type: 'BOOLEAN', value: true } }
  / "on"i    { return { type: 'BOOLEAN', value: true } }
  / "false"i { return { type: 'BOOLEAN', value: false } }
  / "no"i    { return { type: 'BOOLEAN', value: false } }
  / "off"i   { return { type: 'BOOLEAN', value: false } }

_ "whitespace"
  = [ \t\n\r]* Comment _
  / [ \t\n\r]*

ws "mandatory whitespace"
  = [ \t\n\r] _
