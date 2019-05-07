#!/usr/bin/ruby

require_relative './gen_shared'

VERSION_TAG = "v14.3.0"
url = "https://raw.githubusercontent.com/graphql/graphql-js/#{ VERSION_TAG }/src/language/lexer.js"
javascript = `curl --silent '#{ url }'`

haxe = javascript
haxe.sub!(/(import type.*?blockStringValue';)/m, "/* \\1 */")

GenShared::export_to_function!(haxe)

# Inject class / constructor (instead of createLexer)
defs = <<eof
class GeneratedLexer<TOptions> {

public var source:Source;
public var options:TOptions;
public var lastToken:Token;
public var token:Token;
public var line:Int = 1;
public var lineStart:Int = 0;
public var advance:Void->Token;

private function new(opts:TOptions) {
  this.options = opts;
  this.advance = advanceLexer; // odd redirection by .js code
}

public static function createLexer<TOptions>(source:Source, options:TOptions) {
  var startOfFileToken = new Tok(TokenKind.SOF, 0, 0, 0, 0, null);
  var lexer = new GeneratedLexer(options);
  lexer.source = source;
  lexer.lastToken = startOfFileToken;
  lexer.token = startOfFileToken;
  return lexer;
}
eof

haxe.sub!(/public function createLexer.*?return lexer;.*?}/m, defs)

# Lexer<*> to just Lexer
haxe.gsub!(/Lexer<.>/, "Lexer")

# multi-line backticks
haxe.gsub!(/fromCharCode\(\s+code,\s+\)/m, "fromCharCode(code)")

haxe.sub!(/(public function getTokenDesc\(.*?token.kind;.*?})/m, "/* \\1 */")

GenShared::backticks!(haxe)

haxe.gsub!(/^(\s+).*toUpperCase.*$/, "\\1 'ESCMAD' // escaping madness")


GenShared::basic_types_and_junk!(haxe)

GenShared::func_args_trailing_comma!(haxe)
GenShared::func_calls_trailing_comma!(haxe)

# Special characters?
haxe.sub!(/\'\\b\'/, '\'\u0008\' /* backspace? Haxe doesnt like \\b */')
haxe.sub!(/\'\\f\'/, '\'\u000C\' /* form feed? Haxe doesnt like \\f */')

# ESIOK...   ES implied object key name... GRR!
haxe = GenShared::ES_implied_object_keys(haxe)

# TokenKind was already put in astdefs
haxe.gsub!(/export var TokenKind.*?}\);/m, '')
haxe.gsub!(/export type TokenKindEnum.*?;/, '')

haxe.gsub!(/Token \| null/, "Null<Token>")

# ugh, have to move typedef out of class Lexer...
#haxe.gsub!(/export type Lexer.*?};/m, '')
#lexer_typedef = $& # Don't need typedef Lexer, it's now a class
#GenShared::export_type_to_typedef!(lexer_typedef)
#lexer_typedef.gsub!(/\(\):/, ': Void->')
#haxe = haxe + "\n\n} // end of class Lexer\n\n" + lexer_typedef

# Remove the lexer "export" definition, we have a class
haxe.gsub!(/export type Lexer.*?};/m, '')

# Move Tok helper class out of class Lexer
haxe.gsub!(/private function Tok.*?toJSON.*?};\s+};/m, '')
#tok_class = $&
#tok_class.sub!(/value\?:String\){/, "?value:String)\n{")
#tok_defs = "public var value:String;\npublic var next: Null<Token>;\n"
#tok_class.gsub(/(\w+):\s*(.*?),/) { |d|
#  next if d.include?("this")
#  tok_defs = tok_defs + "\npublic var #{ d.sub(/,$/, ";") }"
#}
#tok_class.sub!(/private function Tok/, "class Tok {\n#{ tok_defs }\n\npublic function new")
#tok_class.sub!(/Tok.prototype.toJSON = Tok.prototype.inspect = function toJSON/, "public function toJSON")
#haxe = haxe + "\n\n} // end of class Lexer\n\n" + tok_class + "\n}"


# syntax error now takes line and lineStart (for reporting pos)
haxe.gsub!(/syntaxError\(\s*source/m, "syntaxError(source, line, lineStart")

extraMethods = <<eof

private function syntaxError(source:Source, line:Int, col:Int, start:Int, msg:String): GraphQLError {
  return graphql.parser.Parser.syntaxError(source, line, col, start, msg);
}

eof

haxe = haxe + "\n#{ extraMethods }\n\n} // end of class Lexer"

haxe.gsub!(/new Tok\(/, 'TokUtil.asToken(')

GenShared::case_fall_throughs!(haxe)

# Specific source / charCodeAt / slice functions mapped to tink.parser.StringSlice
haxe.sub!(/(var charCodeAt =.*?slice;)/m, "/* \\1 */")
haxe.gsub!(/charCodeAt.call\(\s*body\s*,\s*/, "/* CCA */source.fastGet(")
haxe.gsub!(/slice.call\(\s*body\s*,\s*(.*?),/, "/* CCA */body.slice(\\1 ... ")
haxe.gsub!(/body.slice\(\s*(.*?),/, "body.slice(\\1 ... ")
haxe.gsub!(/source.body/, "source/* source.body */")

haxe.gsub!(/readToken\(this/, "readToken(cast this")
haxe.gsub!(/token.next \|\|/, "(token.next!=null) ? token.next :")

haxe.gsub!(/(isNaN\(code\))/, "false /* \\1 */")
haxe.gsub!(/JSON.stringify/, "haxe.Json.stringify")

haxe.gsub!(/(function \w+\s*\(\s*source\s*),/, "\\1:Source,")

haxe.gsub!(/(blockStringValue\(\w+\))/, "{ throw 'TODO: implement \\1'; null; }")

haxe.gsub!(/private function lookahead\(/, "public function lookahead(")

haxe.gsub!(/body:String/, "body:Source")

# - - - -  write output
puts <<eof
package graphql.parser;

/* GENERATED BY gen_lexer.rb -- DO NOT EDIT!!! */
/* GENERATED BY gen_lexer.rb -- DO NOT EDIT!!! */
/* GENERATED BY gen_lexer.rb -- DO NOT EDIT!!! */
/* GENERATED BY gen_lexer.rb -- DO NOT EDIT!!! */
/* */
/* based on: #{ url } */
/* */

import graphql.ASTDefs;

import graphql.parser.GeneratedParser;

#{ haxe }

class TokUtil {
public static function asToken(kind: TokenKindEnum,
  start:Int /* number */,
  end:Int /* number */,
  line:Int /* number */,
  column:Int /* number */,
  prev: Null<Token>,
  ?value:String):Token
  {
    return {
      kind:kind,
      start:start,
      end:end,
      line:line,
      column:column,
      value:value,
      prev:prev,
      next:null
    }
  }
}

eof
