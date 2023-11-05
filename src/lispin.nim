import rdstdin, strutils, strformat

type
    LexerTokenType = enum TokenSpecial, TokenSymbol, TokenNumber, TokenString
    LexerToken = object
        tokenType: LexerTokenType
        value: string
    Lexer = object
        code: string
        position: int

proc readSymbol(self: var Lexer): string =
    let
        terminators = " ()\n"
        startPosition = self.position
    while self.position < self.code.len:
        if terminators.contains(self.code[self.position]):
            break
        self.position.inc
    return self.code[startPosition .. (self.position - 1)]

proc readNumber(self: var Lexer): string =
    let sym = self.readSymbol
    if not sym.allCharsInSet(Digits):
        raise newException(ValueError, fmt"ERROR: Invalid number `{sym}`")
    return sym 

proc readString(self: var Lexer): string =
    self.position.inc
    let startPosition = self.position
    while self.position < self.code.len:
        if self.code[self.position] == '"':
            return self.code[startPosition .. (self.position - 1)]
        self.position.inc
    raise newException(ValueError, "ERROR: Unterminated string")

proc tokenize(self: var Lexer): seq[LexerToken] =
    var tokens: seq[LexerToken]
    while self.position < self.code.len:
        let ch = self.code[self.position]
        case ch
        of ' ', '\n': # Skip whitespace
            self.position.inc
        of ';': # Comments, skip until newline
            while self.position < self.code.len:
                if self.code[self.position] == '\n':
                    break
                self.position.inc
            self.position.inc
        of '(', ')': # Special single character tokens
            tokens.add LexerToken(tokenType: TokenSpecial, value: $ch)
            self.position.inc
        of '0' .. '9': # Numbers -- TODO: Negative numbers + floats
            tokens.add LexerToken(tokenType: TokenNumber, value: self.readNumber)
        of '"': # Strings -- TODO: Handle escaped characters
            tokens.add LexerToken(tokenType: TokenString, value: self.readString)
            self.position.inc
        else: # Anything else is parsed as a symbol
            tokens.add LexerToken(tokenType: TokenSymbol, value: self.readSymbol) 
    return tokens

while true:
    try:
        var line: string
        let ok = readLineFromStdin("user> ", line)
        if not ok:
            break
        if line.len > 0:
            var lexer = Lexer(code: line)
            echo lexer.tokenize
    except:
        echo getCurrentExceptionMsg()
        