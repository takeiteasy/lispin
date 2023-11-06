import rdstdin, strutils, strformat, regex

type
    LexerTokenType = enum TokenSpecial, TokenSymbol, TokenNumber, TokenString
    LexerToken = object
        tokenType: LexerTokenType
        value: string
    Lexer = object
        code: string
        position: int
let
    TerminateChars = Whitespace + NewLines + {'(', ')'}

proc readSymbol(self: var Lexer): string =
    let startPosition = self.position
    while self.position < self.code.len:
        if TerminateChars.contains(self.code[self.position]):
            break
        inc self.position
    return self.code[startPosition .. (self.position - 1)]

proc readNumber(self: var Lexer): string =
    let sym = self.readSymbol
    var m: RegexMatch2
    if not match(sym, re2"^-?(\d+|\d{1,3}(,\d{3})*)(\.\d+)?$", m):
        raise newException(ValueError, fmt"ERROR: Invalid number `{sym}`")
    return sym 

proc readString(self: var Lexer): string =
    inc self.position
    let startPosition = self.position
    while self.position < self.code.len:
        if self.code[self.position] == '"':
            var prevChar = self.position - 1
            while self.code[prevChar] == '\\':
                dec prevChar
            var escapeCount = self.position - 1 - prevChar
            if escapeCount mod 2 == 0:
                return self.code[startPosition .. (self.position - 1)]
        inc self.position
    raise newException(ValueError, "ERROR: Unterminated string")

proc peek(self: Lexer): char =
    return (if self.position + 1 >= self.code.len: '\0' else: self.code[self.position + 1])

proc tokenize(self: var Lexer): seq[LexerToken] =
    var tokens: seq[LexerToken]
    while self.position < self.code.len:
        let ch = self.code[self.position]
        case ch
        of Whitespace: # Skip whitespace
            inc self.position
        of ';': # Comments, skip until newline
            while self.position < self.code.len:
                if NewLines.contains(self.code[self.position]):
                    break
                inc self.position
            inc self.position
        of '(', ')': # Special single character tokens
            tokens.add LexerToken(tokenType: TokenSpecial, value: $ch)
            inc self.position
        of '-':
            let nextChar = self.peek
            if Digits.contains(nextChar):
                tokens.add LexerToken(tokenType: TokenNumber, value: self.readNumber)
            else:
                tokens.add LexerToken(tokenType: TokenSymbol, value: self.readSymbol)
        of Digits: # Numbers -- TODO: Negative numbers + floats
            tokens.add LexerToken(tokenType: TokenNumber, value: self.readNumber)
        of '"': # Strings
            tokens.add LexerToken(tokenType: TokenString, value: self.readString)
            inc self.position
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
        