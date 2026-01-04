## IavaScriptvm

An esoteric programming language (meaning that it has no real life use) that I created at my university's compiler classes, using Flex and Bison.
It is made to imitate medieval catholic bibles, so it has some very strict formatting rules. Violation of the formatting rules will result in the compiler "excommunicating", "denouncing" the code written for being "blasphemous". 

### Features

- A very verbose syntax with most of the operators and keywords being words or multiple words (made out of latin words)
- Floats, ints, and arrays made of these, that are declared using ascii art characters for the first character
- Number representation with roman numerals (extended roman numerals so a 32 bit number can be represented)
- Comments being separated from the code by a straight line of "|", or no comments at all 
- No lesser or greater comparison, only equal and non equal :)

### Developer Experience

- Code that's not used for generating ascii art and rules for the ascii is made of latin words for identifiers
- Lexer rules that are so difficult to write, that it's faster to generate them from code; even flex can barely handle them
- Compilation to assembly
- Refusing to use push/pop in assembly (effectively making development harder, and the runtime longer)

### How to use it 

I don't think you would like to know, but I worked on it so, might as well just write it down.

#### Syntax

The basic syntax of the language is not for the faint of heart

##### Keywords

The keywords are verbose and need to be separated from eachother and from literals.

##### Literals

Literals for integers use an extended version of the roman numerals, the original roman numerals are made of the characters: I, V, X, L, C, D, M; these are extended with the characters: T, R, E, W, Q, K, H, G, F, B, S, A; these extend the numbers as one would expect them to.

Literals also need to be preceded by the character †, furthermore 0 is represented by O. 

So the integer 6421 would be represented by †TMCDXXI. Floats are similar, one needs to place a `.` after the whole part of the number then write the fractional part in the same manner. for example 1.1 would be †I.I

Negative numbers need to be preceded by the `negans` keyword. 

Array literals start with the keyword `haec est` and are followed by expressions which are divided by the keyword `et` and finished by the keyword `quae Domino servire vvlt`.

##### Commands

Commands can be declarations, conditional blocks, loop blocks, value assignments, and I/O operations.

Commands end with a `.` and are followed by a new line (and possibly additional white characters).

##### Variables

IavaScriptvm is a strongly typed language with main 2 types (integers and floats), and arrays made of these. 

Variable names can only have characters from the latin alphabet, meaning `u, j and w` cannot be used in them. The first letter is uppercase, the rest is lowercase.

Declaring variables is tricky. When declaring, the first letter of a variable is written with ascii art letters. Depending on the ascii art "font", the type of the variable is decided. Floats are declared with the `AMC AAA01` font, integers are declared with the `AMC Slash` font. These letters are boxed in with `-` and `|` characters for clarity. After writing the name of the variable, an assignment needs to be placed with the `et renascitvr vt` keyword which is followed by the expression whose value will be assigned to the variable.

As an example, declaring an integer variable Temporalis with the value 0 would look like this:

<pre>
-------------
| .s5SSSSs. |
|    SSS    |
|    S%S    |
|    S%S    |
|    S%S    |
|    S%S    |
|    `:;    |
|    ;,.    |
|    ;:'    |
-------------emporalis et renascitvr vt †O .
</pre>

Arrays are similar, but they have to declare their size by writing a numeral on the box, for example, declaring a float array of size 3810 would look like this:

<pre>
M-----------M†
| .S\_SSSs    X
| .SS~SSSSS  |
| S%S   SSSS |
| S%S    S%S |
| S%S SSSS%S |
M S&S  SSS%S |
| S&S    S&S C
| S&S    S&S |
| S*S    S&S |
| S*S    S*S |
| S*S    S*S |
| SSS    S*S |
|        SP  |
|        Y   |
D------C-----Clba et renascitvr vt ....
</pre>

For accessing an element of an array the `de` keyword is followed by the array then the `veni` keyword, than the index of the value is needed.

For example accessing the 2nd element of the array Alba is expressed like so:
`de Alba veni †II`

##### Numeric operations

adding, subracting, multiplying, dividing, negating can be done with the keywords: `plvs`, `minvs`, `mvltiplica per`, `divisa per`, `negans`. For precedence, the IavaScriptvm analogue for `(`-s and `)`-s are the keywords, `vnitas` and `finis`.

##### Comments 

Comments are written beside the program. If there are comments a horizontal line of `|` characters needs to separate the program from the comments.

##### I/O operations

Reading into a variable is done with the `Legamvs verba domini nostri` keyword followed by the variable.

Writing a variable to the console is done with the `Lavdemvs dominvm in his verbis` keword followed by the expression whose value we want to write.

##### Truth values 

One can check equality and inequality between two expressios with the keywords `idem` and `non est idem`.

Logical and and logical or can be done with the keywords: `et` and `avt`.

##### Conditionals

A conditional statement starts with the keyword `Si peccatvm`, followed by a truth expression to evaluate and the keyword `oportet vos poenitenter cvm` then a newline.

After this, one can write commands that will only be evaluated if the the truth value is true.

Optionally, an alternative branch to this can be started with the `Alivd` keyword and a newline.

Finally, the conditional can be finished with the `et Dominvs dimittat vobis` keyword.

##### Loops

A loop is started by the keyword: `Dvm non svnt sine` and a truth expression, followed by the `oportet vos poenitenter cvm` keyword

Commands can be written like with conditionals 

Finally, the loop can be finished with the `et Dominvs dimittat vobis` keyword.

##### The structure of a program

A IavaScriptvm program is written in multiple files with the extension `svm`, each file can have a maximum of 50 lines. A program also needs an enumeration file, which collects the files in order, by specifying the file paths.

A IavaScriptvm program starts with the `LIBER` keyword, followed by the name of the author in the next line.

After this, the commands are written. 

Finally, a program is closed by the `Amen` keyword.

Examples can be found in the exempla folder.

##### How to run your program

Once your code is written, give the enm file to the creo.bat file script (or write a shell script which does the same things as the batch file if you use a real operating system)

### Final thoughts

I had way too much fun with this one, so I had to include it in my repos

