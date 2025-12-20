import 'package:inception/src/document/lexing.dart';

/// Contextualizes a given list of [LexerToken]s, adding semantic meaning to various tokens
/// based on the specific programming language and its grammar.
///
/// For example, a [Contextualizer] might differentiate a greater than operator `a > b` from
/// a generic brace operator `<Foo>`.
abstract class Contextualizer {
  /// Adds context to the given [lexerTokens]s within [code] text.
  List<SemanticToken> contextualize(String code, List<LexerToken> lexerTokens);
}

class SemanticToken {
  const SemanticToken.standard(this.start, this.end, this.standardKind) : customKind = null;

  const SemanticToken.custom(this.start, this.end, this.customKind) : standardKind = null;

  final int start;
  final int end;

  bool get isStandard => standardKind != null;
  final SemanticKind? standardKind;

  bool get isCustom => customKind != null;
  final String? customKind;
}

enum SemanticKind {
  // ----- Literals -----
  string, // string literal
  number, // numeric literal
  boolean, // true/false literals
  nullValue, // null, nil, None, etc.
  character, // char literal
  regex, // regex literal
  // ----- Identifiers -----
  identifier, // variable, function, parameter, etc.
  functionName, // declaration of a function
  className, // class declaration
  typeName, // type annotation / type name
  enumMember, // enum value
  moduleName, // module import/export
  propertyName, // object/struct property
  // ----- Keywords -----
  keyword, // general language keywords
  controlFlow, // if, else, switch, while, for, break, continue, return
  visibility, // public, private, protected, internal
  declaration, // var, let, const, type, typedef, function
  // ----- Operators -----
  operator, // general operator
  assignment, // =
  comparison, // ==, !=, >, <, >=, <=
  arithmetic, // +, -, *, /, %, **
  logical, // &&, ||, !
  bitwise, // &, |, ^, ~, <<, >>
  increment, // ++, --
  ternary, // ? :
  // ----- Punctuation -----
  punctuation, // ; , . :
  brackets, // (), {}, []
  genericBrace, // <>, type parameters
  comma, // ,
  colon, // :
  semicolon, // ;
  // ----- Comments -----
  comment, // any comment
  docComment, // documentation comment, e.g., /** */ or ///
  // ----- Annotations / Decorators -----
  annotation, // @decorator, #[attribute]
  // ----- Miscellaneous -----
  whitespace, // spaces, tabs, newlines
  unknown, // unrecognized token
  error, // syntactically invalid token
}
