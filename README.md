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

I'll spare the details since nobody would care about it to be frank. But if you are interested how a program would look in IavaScriptvm, in the exempla directory there are some examples

### Final thoughts

I had way too much fun with this one, so I had to include it in my repo
