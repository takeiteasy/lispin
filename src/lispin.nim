import rdstdin, strutils, strformat, regex, options, macros

type
    LexerTokenKind = enum TokenSpecial, TokenSymbol, TokenNumber, TokenString
    LexerToken = object
        kind: LexerTokenKind
        value: string
    Lexer = object
        code: string
        tokens: seq[LexerToken]
        position: int
let
    TerminateChars = Whitespace + NewLines + {'(', ')'}

proc peekChar(lexer: Lexer): Option[char] =
    if lexer.position < lexer.code.len:
        return lexer.code[lexer.position].some

proc peekNextChar(lexer: Lexer): Option[char] =
    if lexer.position + 1 < lexer.code.len:
        return lexer.code[lexer.position + 1].some

proc nextChar(lexer: var Lexer): Option[char] =
    if lexer.position < lexer.code.len:
        result = lexer.code[lexer.position].some
        inc lexer.position

proc readSpecial(lexer: var Lexer): string =
    $lexer.nextChar.get

proc readSymbol(lexer: var Lexer): string =
    let startPosition = lexer.position
    while true:
        let c = lexer.peekChar
        if c.isNone or TerminateChars.contains(c.get):
            break
        discard lexer.nextChar
    return lexer.code[startPosition .. (lexer.position - 1)]

proc readNumber(lexer: var Lexer): string =
    let sym = lexer.readSymbol
    var m: RegexMatch2
    # Regex taken from: https://stackoverflow.com/a/5917250
    if not match(sym, re2"^-?(\d+|\d{1,3}(,\d{3})*)(\.\d+)?$", m):
        raise newException(ValueError, fmt"ERROR: Invalid number `{sym}`")
    return sym 

proc readString(lexer: var Lexer): string =
    discard lexer.nextChar # Skip opening quote
    let startPosition = lexer.position
    while true:
        let c = lexer.peekChar
        if c.isNone:
            raise newException(ValueError, "ERROR: Unterminated string")
        if c.get == '"':
            var prevChar = lexer.position - 1
            while lexer.code[prevChar] == '\\':
                dec prevChar
            var escapeCount = lexer.position - 1 - prevChar
            if escapeCount mod 2 == 0:
                return lexer.code[startPosition .. (lexer.position - 1)]
        discard lexer.nextChar
    
macro addToken(kind: static[string]): untyped =
    parseStmt(fmt"lexer.tokens.add LexerToken(kind: Token{kind}, value: lexer.read{kind})")

proc parse(str: string): void =
    var lexer = Lexer(code: str)
    while true:
        var c = lexer.peekChar
        if c.isNone:
            break
        case c.get
        of Whitespace:
            discard lexer.nextChar
        of ';':
            while not c.isNone and not NewLines.contains(c.get):
                c = lexer.nextChar
        of '(', ')':
            addToken("Special")
        of Digits:
            addToken("Number")
        of '-':
            c = lexer.peekNextChar
            if c.isNone or not Digits.contains(c.get):
                addToken("Symbol")
            else:
                addToken("Number")
        of '"':
            addToken("String")
            discard lexer.nextChar # Skip closing quote
        else:
            addToken("Symbol")
    echo lexer.tokens

when isMainModule:
    while true:
        try:
            var line: string
            let ok = readLineFromStdin("user> ", line)
            if not ok:
                break
            if line.len > 0:
                line.parse
        except:
            echo getCurrentExceptionMsg()
            