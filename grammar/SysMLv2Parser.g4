/*
 * SysML v2 ANTLR4 Grammar
 * Derived from the OMG SysML v2 specification (KEBNF format).
 * Source: https://github.com/Systems-Modeling/SysML-v2-Release
 * Generator: https://github.com/daltskin/sysml-v2-grammar
 * License: MIT
 */

parser grammar SysMLv2Parser;

options {
    tokenVocab = SysMLv2Lexer;
}

// $antlr-format alignTrailingComments true, columnLimit 150, useTab false
// $antlr-format allowShortRulesOnASingleLine false, allowShortBlocksOnASingleLine true
// $antlr-format alignSemicolons hanging, alignColons hanging
// $antlr-format minEmptyLines 1, maxEmptyLinesToKeep 1, reflowComments false

// ===== Expression rules (explicit precedence layers) =====

// Evidence: KerML 1.0 Clause 8.2.5.8.1 Table 6 makes `if` the lowest-precedence operator.
// Reference: https://www.omg.org/spec/KerML/1.0/PDF#page=124 and KEBNF https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L932-L947
ownedExpression
    : operatorExpression
    ;

// Evidence: KEBNF `ConditionalExpression` has three `OwnedExpression` operands; paired conditional layers make that recursion available as a final operand without an ANTLR exact ambiguity between an `else` branch and an outer trailing operator.
// Reference: KEBNF https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L932-L947 and argument recursion https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L1003-L1010
// Direct runtime evidence: a locally rebuilt official Pilot from first-party commit `fa709f28dfd49dfdb7ee83e4e19da2f57e0eb3aa` rejected the four KEBNF-derived conditional-operand probes `a + if b ? c else d`, `-if b ? c else d`, `a ** if b ? c else d`, and `a ?? if b ? c else d`.
// This is a disclosed Pilot acceptance-set discrepancy (artifact SHA-256 `f1e1880b337ed3c50bc65c32599f43ec9148cc4ca47ef91a99c5022ec677d9ac`); KEBNF is declarative, so its result is derived from the cited productions rather than executed.
// Pilot source: [ConditionalExpression](https://github.com/Systems-Modeling/SysML-v2-Pilot-Implementation/blob/fa709f28dfd49dfdb7ee83e4e19da2f57e0eb3aa/org.omg.kerml.expressions.xtext/src/org/omg/kerml/expressions/xtext/KerMLExpressions.xtext#L43-L57); normative source: [KEBNF OwnedExpression and ConditionalExpression](https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L932-L947).
conditionalExpression
    : IF ownedExpression QUESTION ownedExpression ELSE ownedExpression
    ;

// Evidence: KerML 1.0 Clause 8.2.5.8.1 Note 2 says KEBNF precedence is implicit, all binary operators are left-associative except exponentiation, and Table 6 orders these tiers from high to low.
// Reference: https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L1061-L1064
operatorExpression
    : nullCoalescingExpression
    | nullCoalescingConditionalExpression
    ;

// Evidence map: KEBNF `ConditionalBinaryOperator` groups `??`, `or`, `and`, and `implies`; `BinaryOperator` groups `|`, `&`, `xor`, equality, relational, range, additive, multiplicative, and exponentiation.
// Reference: KEBNF https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L949-L969; normative precedence and associativity: KerML 1.0 Clause 8.2.5.8.1 Table 6 and Note 2 https://www.omg.org/spec/KerML/1.0/PDF#page=124
// Ambiguity control: every conditional-containing layer ends with exactly one conditional child, so the current tier cannot consume an operator after that conditional; the branch's recursive `OwnedExpression` owns it instead.
// This paired-state invariant preserves KEBNF recursion while avoiding an exact ANTLR ambiguity at the conditional `else` boundary.
// References: [KerML 1.0 Clause 8.2.5.8.1, Table 6 and Note 2](https://www.omg.org/spec/KerML/1.0/PDF#page=124); [KEBNF precedence note](https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L1061-L1064).
// Local tier evidence: `??` is the lowest binary tier and belongs to KEBNF `ConditionalBinaryOperatorExpression`; the direct Pilot grammar defines it as `NullCoalescingExpression`.
// References: [KEBNF ConditionalBinaryOperatorExpression](https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L949-L953); [Pilot NullCoalescingExpression](https://github.com/Systems-Modeling/SysML-v2-Pilot-Implementation/blob/fa709f28dfd49dfdb7ee83e4e19da2f57e0eb3aa/org.omg.kerml.expressions.xtext/src/org/omg/kerml/expressions/xtext/KerMLExpressions.xtext#L63-L72).
nullCoalescingExpression
    : impliesExpression ( QUESTION_QUESTION impliesExpression )*
    ;

nullCoalescingConditionalExpression
    : impliesExpression ( QUESTION_QUESTION impliesExpression )* QUESTION_QUESTION impliesConditionalExpression
    | impliesConditionalExpression
    ;

// Local tier evidence: `implies`, `or`, `xor`, and `and` are the remaining conditional-binary tiers; each repeated operator is left-associative and follows Table 6's high-to-low ordering.
// References: [KEBNF ConditionalBinaryOperatorExpression](https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L949-L953); [Pilot logical expression rules](https://github.com/Systems-Modeling/SysML-v2-Pilot-Implementation/blob/fa709f28dfd49dfdb7ee83e4e19da2f57e0eb3aa/org.omg.kerml.expressions.xtext/src/org/omg/kerml/expressions/xtext/KerMLExpressions.xtext#L74-L144).
impliesExpression
    : orExpression ( IMPLIES orExpression )*
    ;

impliesConditionalExpression
    : orExpression ( IMPLIES orExpression )* IMPLIES orConditionalExpression
    | orConditionalExpression
    ;

orExpression
    : xorExpression ( ( PIPE | OR ) xorExpression )*
    ;

orConditionalExpression
    : xorExpression ( ( PIPE | OR ) xorExpression )* ( PIPE | OR ) xorConditionalExpression
    | xorConditionalExpression
    ;

xorExpression
    : andExpression ( XOR andExpression )*
    ;

xorConditionalExpression
    : andExpression ( XOR andExpression )* XOR andConditionalExpression
    | andConditionalExpression
    ;

andExpression
    : equalityExpression ( ( AMP | AND ) equalityExpression )*
    ;

andConditionalExpression
    : equalityExpression ( ( AMP | AND ) equalityExpression )* ( AMP | AND ) equalityConditionalExpression
    | equalityConditionalExpression
    ;

// Local tier evidence: equality is above `and` and below classification; classification remains a single optional suffix between relational and equality.
// References: [KEBNF BinaryOperatorExpression](https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L958-L969); [KEBNF ClassificationExpression](https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L974-L997); [Pilot equality and classification rules](https://github.com/Systems-Modeling/SysML-v2-Pilot-Implementation/blob/fa709f28dfd49dfdb7ee83e4e19da2f57e0eb3aa/org.omg.kerml.expressions.xtext/src/org/omg/kerml/expressions/xtext/KerMLExpressions.xtext#L146-L183).
equalityExpression
    : classificationExpression ( ( EQ_EQ | BANG_EQ | EQ_EQ_EQ | BANG_EQ_EQ ) classificationExpression )*
    ;

equalityConditionalExpression
    : classificationExpression ( ( EQ_EQ | BANG_EQ | EQ_EQ_EQ | BANG_EQ_EQ ) classificationExpression )* ( EQ_EQ | BANG_EQ | EQ_EQ_EQ | BANG_EQ_EQ ) classificationConditionalExpression
    | classificationConditionalExpression
    ;

// Evidence: KerML 1.0 Clause 8.2.5.8.1 defines one optional classification/cast suffix, and the Pilot places it between relational and equality expressions.
// Reference: KEBNF https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L974-L997; Pilot https://github.com/Systems-Modeling/SysML-v2-Pilot-Implementation/blob/fa709f28dfd49dfdb7ee83e4e19da2f57e0eb3aa/org.omg.kerml.expressions.xtext/src/org/omg/kerml/expressions/xtext/KerMLExpressions.xtext#L156-L183
// Evidence: KEBNF MetaclassificationExpression uses MetadataReference -> ElementReferenceMember, and KerML 1.0 Clause 7.4.9.2 shows `designModel @@ ApprovalAnnotation` and `sensors meta KerML::Feature`; therefore `@@` and `meta` require a qualified name operand and cannot be prefix operators.
// Reference: KerML 1.0 Clause 7.4.9.2, https://www.omg.org/spec/KerML/1.0/PDF, and KEBNF https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L994-L1001 and https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L1021-L1037
// Observed PR #10 behavior under ANTLR 4.13.2: `a istype T + b` became `(a istype T) + b`, `a istype T as U` was accepted, and bare `@@ T` was accepted; these forms now stop at the explicit classification boundary or require a qualified name.
classificationExpression
    : relationalExpression ( ( ISTYPE | HASTYPE | AT_SIGN | AS ) typeReference )?
    | ( ISTYPE | HASTYPE | AT_SIGN | AS ) typeReference
    | qualifiedName ( AT_AT | META ) typeReference
    ;

// Local tier evidence: relational, range, additive, and multiplicative layers follow the KEBNF `BinaryOperatorExpression` family and are left-associative under Table 6.
// References: [KEBNF BinaryOperatorExpression](https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L958-L969); [Pilot relational through multiplicative rules](https://github.com/Systems-Modeling/SysML-v2-Pilot-Implementation/blob/fa709f28dfd49dfdb7ee83e4e19da2f57e0eb3aa/org.omg.kerml.expressions.xtext/src/org/omg/kerml/expressions/xtext/KerMLExpressions.xtext#L233-L269).
relationalExpression
    : rangeExpression ( ( LT | GT | LE | GE ) rangeExpression )*
    ;

relationalConditionalExpression
    : rangeExpression ( ( LT | GT | LE | GE ) rangeExpression )* ( LT | GT | LE | GE ) rangeConditionalExpression
    | rangeConditionalExpression
    ;

rangeExpression
    : additiveExpression ( DOT_DOT additiveExpression )*
    ;

rangeConditionalExpression
    : additiveExpression ( DOT_DOT additiveExpression )* DOT_DOT additiveConditionalExpression
    | additiveConditionalExpression
    ;

additiveExpression
    : multiplicativeExpression ( ( PLUS | MINUS ) multiplicativeExpression )*
    ;

additiveConditionalExpression
    : multiplicativeExpression ( ( PLUS | MINUS ) multiplicativeExpression )* ( PLUS | MINUS ) multiplicativeConditionalExpression
    | multiplicativeConditionalExpression
    ;

multiplicativeExpression
    : exponentiationExpression ( ( STAR | SLASH | PERCENT ) exponentiationExpression )*
    ;

multiplicativeConditionalExpression
    : exponentiationExpression ( ( STAR | SLASH | PERCENT ) exponentiationExpression )* ( STAR | SLASH | PERCENT ) exponentiationConditionalExpression
    | exponentiationConditionalExpression
    ;

// Local tier evidence: exponentiation is above multiplicative operators and is the only right-associative binary tier in KerML Table 6 and Note 2.
// References: [KerML 1.0 Clause 8.2.5.8.1, Table 6 and Note 2](https://www.omg.org/spec/KerML/1.0/PDF#page=124); [KEBNF BinaryOperatorExpression](https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L958-L969); [Pilot ExponentiationExpression](https://github.com/Systems-Modeling/SysML-v2-Pilot-Implementation/blob/fa709f28dfd49dfdb7ee83e4e19da2f57e0eb3aa/org.omg.kerml.expressions.xtext/src/org/omg/kerml/expressions/xtext/KerMLExpressions.xtext#L271-L278).
exponentiationExpression
    : unaryExpression ( ( STAR_STAR | CARET ) exponentiationExpression )?
    ;

exponentiationConditionalExpression
    : unaryExpression ( ( STAR_STAR | CARET ) exponentiationConditionalExpression )
    | unaryConditionalExpression
    ;

// Evidence: KerML 1.0 Table 6 places `all` and unary operators above every binary tier; the KEBNF defines `all` as an extent expression.
// References: [KerML 1.0 Clause 8.2.5.8.1, Table 6](https://www.omg.org/spec/KerML/1.0/PDF#page=124); [KEBNF ExtentExpression and UnaryOperatorExpression](https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L971-L977); [Pilot UnaryExpression](https://github.com/Systems-Modeling/SysML-v2-Pilot-Implementation/blob/fa709f28dfd49dfdb7ee83e4e19da2f57e0eb3aa/org.omg.kerml.expressions.xtext/src/org/omg/kerml/expressions/xtext/KerMLExpressions.xtext#L280-L295).
unaryExpression
    : ( PLUS | MINUS | TILDE | NOT ) unaryExpression
    | extentExpression
    ;

unaryConditionalExpression
    : ( PLUS | MINUS | TILDE | NOT ) unaryConditionalExpression
    | conditionalExpression
    ;

classificationConditionalExpression
    : relationalConditionalExpression
    ;

extentExpression
    : ALL typeReference
    | primaryExpression
    ;

// Evidence: KerML 1.0 Clause 8.2.5.8.2 defines only the listed primary postfix forms; brackets and index expressions require non-empty sequences, while arrow operations require a body, function reference, or argument list.
// Reference: https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L1068-L1178 and Pilot https://github.com/Systems-Modeling/SysML-v2-Pilot-Implementation/blob/fa709f28dfd49dfdb7ee83e4e19da2f57e0eb3aa/org.omg.kerml.expressions.xtext/src/org/omg/kerml/expressions/xtext/KerMLExpressions.xtext#L300-L324
// Observed PR #10 behavior under ANTLR 4.13.2: `a[]`, `a#()`, and `a(b)(c)` were accepted, while `a.{b}` and `a->F g` were rejected; this structure follows the KEBNF forms instead.
primaryExpression
    : baseExpression
      ( DOT featureChainMember )?
      (
        (
            LBRACK sequenceExpressionList RBRACK
          | HASH LPAREN sequenceExpressionList RPAREN
          | ARROW featureChainMember ( bodyExpression | qualifiedName | argumentList )
          | DOT bodyExpression
          | DOT_QUESTION bodyExpression
        )
        ( DOT featureChainMember )?
      )*
    ;

typeReference
    : qualifiedName
    ;

// Evidence: KEBNF Clause 8.2.5.8.2 separates non-empty SequenceExpression from `()` NullExpression and permits one trailing comma in SequenceExpressionList.
// Reference: https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L1099-L1118
sequenceExpression
    : LPAREN sequenceExpressionList RPAREN
    ;

sequenceExpressionList
    : ownedExpression ( COMMA ownedExpression )* COMMA?
    ;

// Evidence: KEBNF Clause 8.2.5.8.3 separates FeatureReferenceExpression, MetadataAccessExpression, and InvocationExpression; InvocationExpression accepts an InstantiatedTypeMember plus ArgumentList.
// Reference: https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L1198-L1229
// Evidence: REGULAR_COMMENT is a model-owned comment body, while ML_NOTE is hidden lexical trivia; neither is a base expression in the official KEBNF or Pilot.
// Reference: KEBNF https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L32-L46; Pilot https://github.com/Systems-Modeling/SysML-v2-Pilot-Implementation/blob/fa709f28dfd49dfdb7ee83e4e19da2f57e0eb3aa/org.omg.kerml.expressions.xtext/src/org/omg/kerml/expressions/xtext/KerMLExpressions.xtext#L349-L378
baseExpression
    : nullExpression
    | literalExpression
    | featureReferenceExpression
    | metadataAccessExpression
    | invocationExpression
    | constructorExpression
    | bodyExpression
    | sequenceExpression
    ;

nullExpression
    : NULL
    | LPAREN RPAREN
    ;

featureReferenceExpression
    : qualifiedName
    ;

metadataAccessExpression
    : qualifiedName DOT METADATA
    ;

invocationExpression
    : featureChainMember argumentList
    ;

constructorExpression
    : NEW featureChainMember argumentList
    ;

// Evidence: the normative KerML KEBNF defines ExpressionBody as `{ FunctionBodyPart }` (FunctionBodyPart permits type-body members plus an optional result); the SysML KEBNF defines CalculationBody with `';'` and a braced form; the official SysML Pilot overrides ExpressionBody with CalculationBody.
// Reference: KerML FunctionBody https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L876-L877; FunctionBodyPart https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L879-L883; ExpressionBody https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L1253-L1260; SysML CalculationBody https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/SysML-textual-bnf.kebnf#L1363-L1378; SysML Pilot CalculationBody https://github.com/Systems-Modeling/SysML-v2-Pilot-Implementation/blob/fa709f28dfd49dfdb7ee83e4e19da2f57e0eb3aa/org.omg.sysml.xtext/src/org/omg/sysml/xtext/SysML.xtext#L1947-L1969 and override https://github.com/Systems-Modeling/SysML-v2-Pilot-Implementation/blob/fa709f28dfd49dfdb7ee83e4e19da2f57e0eb3aa/org.omg.sysml.xtext/src/org/omg/sysml/xtext/SysML.xtext#L2436-L2439
// This combined SysML grammar follows the first-party SysML override: the braced branch accepts body parameters, action/return members, and a final result, while the semicolon branch preserves the official empty-body form. Using generic FunctionBodyPart here would make a bare result such as `a.{ x }` compete with a type-body feature member.
bodyExpression
    : SEMI
    | LBRACE calculationBodyPart RBRACE
    ;

argumentList
    : LPAREN ( positionalArgumentList | namedArgumentList )? RPAREN
    ;

positionalArgumentList
    : ownedExpression ( COMMA ownedExpression )*
    ;

namedArgumentList
    : namedArgument ( COMMA namedArgument )*
    ;

namedArgument
    : qualifiedName EQ ownedExpression
    ;

literalExpression
    : literalBoolean
    | literalString
    | literalInteger
    | literalReal
    | literalInfinity
    ;

literalBoolean : TRUE | FALSE ;
literalString : DOUBLE_STRING ;
literalInteger : INTEGER ;
literalReal : REAL ;
literalInfinity : STAR ;

argumentMember
    : ownedExpression
    ;

argumentExpressionMember
    : ownedExpression
    ;

// ===== Name rule (Identifier or UnrestrictedName) =====

name
    : IDENTIFIER
    | STRING
    | unreservedKeyword
    ;

// Evidence: the official Pilot Name rule is ID | UNRESTRICTED_NAME;
// direct Pilot lexing emits bare `typed` as ID and accepts it in OwnedExpression.
// Reference: https://github.com/Systems-Modeling/SysML-v2-Pilot-Implementation/blob/fa709f28dfd49dfdb7ee83e4e19da2f57e0eb3aa/org.omg.kerml.expressions.xtext/src/org/omg/kerml/expressions/xtext/KerMLExpressions.xtext#L534-L550
// Keywords that appear as names in the official OMG standard library.
// These are contextually unreserved — valid as identifiers in name positions.
unreservedKeyword
    : TYPE
    | MULTIPLICITY
    | VAR
    | TYPED
    | STEP
    | FEATURE
    | BEHAVIOR
    | FUNCTION
    | MEMBER
    | PREDICATE
    | INTERACTION
    | METACLASS
    ;

// ===== Parser rules =====

identification
    : LT name GT name
    | LT name GT
    | name
    ;

relationshipBody
    : SEMI
    | LBRACE relationshipOwnedElement* RBRACE
    | LBRACE ( ownedAnnotation )* RBRACE
    ;

relationshipOwnedElement
    : ownedRelatedElement
    | ownedAnnotation
    ;

ownedRelatedElement
    : nonFeatureElement
    | featureElement
    ;

dependency
    : ( prefixMetadataAnnotation )* DEPENDENCY ( identification? FROM )? qualifiedName ( COMMA qualifiedName )* TO qualifiedName ( COMMA qualifiedName )* relationshipBody
    | ( prefixMetadataAnnotation )* DEPENDENCY dependencyDeclaration relationshipBody
    ;

annotation
    : qualifiedName
    ;

ownedAnnotation
    : annotatingElement
    ;

annotatingElement
    : comment
    | documentation
    | textualRepresentation
    | metadataFeature
    ;

comment
    : ( COMMENT identification? ( ABOUT annotation ( COMMA annotation )* )? )? ( LOCALE DOUBLE_STRING )? REGULAR_COMMENT
    ;

documentation
    : DOC identification? ( LOCALE DOUBLE_STRING )? REGULAR_COMMENT
    ;

textualRepresentation
    : ( REP identification? )? LANGUAGE DOUBLE_STRING REGULAR_COMMENT
    ;

rootNamespace
    : packageBodyElement* EOF
    ;

namespace
    : ( prefixMetadataMember )* namespaceDeclaration namespaceBody
    ;

namespaceDeclaration
    : NAMESPACE identification?
    ;

namespaceBody
    : SEMI
    | LBRACE namespaceBodyElement* RBRACE
    ;

namespaceBodyElement
    : namespaceMember
    | aliasMember
    | importRule
    ;

memberPrefix
    : ( visibilityIndicator )?
    ;

visibilityIndicator
    : PUBLIC
    | PRIVATE
    | PROTECTED
    ;

namespaceMember
    : nonFeatureMember
    | namespaceFeatureMember
    ;

nonFeatureMember
    : memberPrefix memberElement
    ;

namespaceFeatureMember
    : memberPrefix featureElement
    ;

aliasMember
    : memberPrefix ALIAS ( LT name GT )? ( name )? FOR qualifiedName relationshipBody
    ;

qualifiedName
    : ( DOLLAR COLON_COLON )? ( name COLON_COLON )* name
    ;

importRule
    : ( visibilityIndicator )? IMPORT ( ALL )? importDeclaration relationshipBody
    ;

importDeclaration
    : membershipImport
    | namespaceImport
    ;

membershipImport
    : qualifiedName ( COLON_COLON STAR_STAR )?
    ;

namespaceImport
    : qualifiedName COLON_COLON STAR ( COLON_COLON STAR_STAR )?
    | filterPackage
    ;

filterPackage
    : filterPackageImportDeclaration ( filterPackageMember )+
    ;

filterPackageMember
    : LBRACK ownedExpression RBRACK
    ;

memberElement
    : annotatingElement
    | nonFeatureElement
    ;

nonFeatureElement
    : dependency
    | namespace
    | type
    | classifier
    | dataType
    | class
    | structure
    | metaclass
    | association
    | associationStructure
    | interaction
    | behavior
    | function
    | predicate
    | multiplicity
    | package
    | libraryPackage
    | specialization
    | conjugation
    | subclassification
    | disjoining
    | featureInverting
    | featureTyping
    | subsetting
    | redefinition
    | typeFeaturing
    ;

featureElement
    : feature
    | step
    | expression
    | booleanExpression
    | invariant
    | connector
    | bindingConnector
    | succession
    | flow
    | successionFlow
    ;

type
    : typePrefix TYPE typeDeclaration typeBody
    ;

typePrefix
    : ( ABSTRACT )? ( prefixMetadataMember )*
    ;

typeDeclaration
    : ( ALL )? identification? ( ownedMultiplicity )? ( specializationPart | conjugationPart )+ typeRelationshipPart*
    ;

specializationPart
    : ( COLON_GT | SPECIALIZES ) ownedSpecialization ( COMMA ownedSpecialization )*
    ;

conjugationPart
    : ( TILDE | CONJUGATES ) ownedConjugation
    ;

typeRelationshipPart
    : disjoiningPart
    | unioningPart
    | intersectingPart
    | differencingPart
    ;

disjoiningPart
    : DISJOINT FROM ownedDisjoining ( COMMA ownedDisjoining )*
    ;

unioningPart
    : UNIONS unioning ( COMMA unioning )*
    ;

intersectingPart
    : INTERSECTS intersecting ( COMMA intersecting )*
    ;

differencingPart
    : DIFFERENCES differencing ( COMMA differencing )*
    ;

typeBody
    : SEMI
    | LBRACE typeBodyElement* RBRACE
    ;

typeBodyElement
    : nonFeatureMember
    | featureMember
    | aliasMember
    | importRule
    ;

specialization
    : ( SPECIALIZATION identification? )? SUBTYPE specificType ( COLON_GT | SPECIALIZES ) generalType relationshipBody
    ;

ownedSpecialization
    : generalType
    ;

specificType
    : qualifiedName ( DOT qualifiedName )*
    ;

generalType
    : qualifiedName ( DOT qualifiedName )*
    ;

conjugation
    : ( CONJUGATION identification? )? CONJUGATE qualifiedName ( DOT qualifiedName )* ( TILDE | CONJUGATES ) qualifiedName ( DOT qualifiedName )* relationshipBody
    ;

ownedConjugation
    : qualifiedName ( DOT qualifiedName )*
    ;

disjoining
    : ( DISJOINING identification? )? DISJOINT qualifiedName ( DOT qualifiedName )* FROM qualifiedName ( DOT qualifiedName )* relationshipBody
    ;

ownedDisjoining
    : qualifiedName ( DOT qualifiedName )*
    ;

unioning
    : qualifiedName ( DOT qualifiedName )*
    ;

intersecting
    : qualifiedName ( DOT qualifiedName )*
    ;

differencing
    : qualifiedName ( DOT qualifiedName )*
    ;

featureMember
    : typeFeatureMember
    | ownedFeatureMember
    ;

typeFeatureMember
    : memberPrefix MEMBER featureElement
    ;

ownedFeatureMember
    : memberPrefix featureElement
    ;

classifier
    : typePrefix CLASSIFIER classifierDeclaration typeBody
    ;

classifierDeclaration
    : ( ALL )? identification? ( ownedMultiplicity )? ( superclassingPart | conjugationPart )? typeRelationshipPart*
    ;

superclassingPart
    : ( COLON_GT | SPECIALIZES ) ownedSubclassification ( COMMA ownedSubclassification )*
    ;

subclassification
    : ( SPECIALIZATION identification? )? SUBCLASSIFIER qualifiedName ( COLON_GT | SPECIALIZES ) qualifiedName relationshipBody
    ;

ownedSubclassification
    : qualifiedName
    ;

feature
    : ( featurePrefix ( FEATURE | prefixMetadataMember ) featureDeclaration? | ( endFeaturePrefix | basicFeaturePrefix ) ( REF )? featureDeclaration ) valuePart? typeBody
    ;

endFeaturePrefix
    : ( CONST )? END
    ;

basicFeaturePrefix
    : ( featureDirection )? ( DERIVED )? ( ABSTRACT )? ( COMPOSITE | PORTION )? ( VAR | CONST )?
    ;

featurePrefix
    : ( endFeaturePrefix ownedCrossFeatureMember | basicFeaturePrefix ) ( prefixMetadataMember )*
    ;

ownedCrossFeatureMember
    : ownedCrossFeature
    ;

ownedCrossFeature
    : basicFeaturePrefix featureDeclaration
    | basicUsagePrefix usageDeclaration?
    ;

featureDirection
    : IN
    | OUT
    | INOUT
    ;

featureDeclaration
    : ( ALL )? ( featureIdentification ( featureSpecializationPart | conjugationPart )? | featureSpecializationPart | conjugationPart ) featureRelationshipPart*
    ;

featureIdentification
    : LT name GT ( name )?
    | name
    ;

featureRelationshipPart
    : typeRelationshipPart
    | chainingPart
    | invertingPart
    | typeFeaturingPart
    ;

chainingPart
    : CHAINS qualifiedName ( DOT qualifiedName )*
    ;

invertingPart
    : INVERSE OF ownedFeatureInverting
    ;

typeFeaturingPart
    : FEATURED BY ownedTypeFeaturing ( COMMA ownedTypeFeaturing )*
    ;

featureSpecializationPart
    : featureSpecialization+ multiplicityPart? featureSpecialization*
    | multiplicityPart featureSpecialization*
    ;

multiplicityPart
    : ownedMultiplicity ( ORDERED ( NONUNIQUE )? | NONUNIQUE ( ORDERED )? )?
    | ( ORDERED ( NONUNIQUE )? | NONUNIQUE ( ORDERED )? )
    ;

featureSpecialization
    : typings
    | subsettings
    | references
    | crosses
    | redefinitions
    ;

typings
    : typedBy ( COMMA featureTyping )*
    ;

typedBy
    : ( COLON | TYPED BY | DEFINED BY ) featureTyping
    ;

subsettings
    : subsets ( COMMA ownedSubsetting )*
    ;

subsets
    : ( COLON_GT | SUBSETS ) ownedSubsetting
    ;

references
    : ( COLON_COLON_GT | REFERENCES ) ownedReferenceSubsetting
    ;

crosses
    : ( FAT_ARROW | CROSSES ) ownedCrossSubsetting
    ;

redefinitions
    : redefines ( COMMA ownedRedefinition )*
    ;

redefines
    : ( COLON_GT_GT | REDEFINES ) ownedRedefinition
    ;

featureTyping
    : ( SPECIALIZATION identification? )? TYPING qualifiedName ( COLON | TYPED BY ) generalType relationshipBody
    | ownedFeatureTyping
    | conjugatedPortTyping
    ;

ownedFeatureTyping
    : qualifiedName ( DOT qualifiedName )*
    ;

subsetting
    : ( SPECIALIZATION identification? )? SUBSET specificType ( COLON_GT | SUBSETS ) generalType relationshipBody
    ;

ownedSubsetting
    : qualifiedName ( DOT qualifiedName )*
    ;

ownedReferenceSubsetting
    : qualifiedName ( DOT qualifiedName )*
    ;

ownedCrossSubsetting
    : qualifiedName ( DOT qualifiedName )*
    ;

redefinition
    : ( SPECIALIZATION identification? )? REDEFINITION specificType ( COLON_GT_GT | REDEFINES ) generalType relationshipBody
    ;

ownedRedefinition
    : qualifiedName ( DOT qualifiedName )*
    ;

featureInverting
    : ( INVERTING identification? )? INVERSE qualifiedName ( DOT qualifiedName )* OF qualifiedName ( DOT qualifiedName )* relationshipBody
    ;

ownedFeatureInverting
    : qualifiedName ( DOT qualifiedName )*
    ;

typeFeaturing
    : FEATURING ( identification? OF )? qualifiedName BY qualifiedName relationshipBody
    ;

ownedTypeFeaturing
    : qualifiedName
    ;

dataType
    : typePrefix DATATYPE classifierDeclaration typeBody
    ;

class
    : typePrefix CLASS classifierDeclaration typeBody
    ;

structure
    : typePrefix STRUCT classifierDeclaration typeBody
    ;

association
    : typePrefix ASSOC classifierDeclaration typeBody
    ;

associationStructure
    : typePrefix ASSOC STRUCT classifierDeclaration typeBody
    ;

connector
    : featurePrefix CONNECTOR ( featureDeclaration? valuePart? | connectorDeclaration ) typeBody
    ;

connectorDeclaration
    : binaryConnectorDeclaration
    | naryConnectorDeclaration
    ;

binaryConnectorDeclaration
    : ( featureDeclaration? FROM | ALL FROM? )? connectorEndMember TO connectorEndMember
    ;

naryConnectorDeclaration
    : featureDeclaration? LPAREN connectorEndMember COMMA connectorEndMember ( COMMA connectorEndMember )* RPAREN
    ;

connectorEndMember
    : connectorEnd
    ;

connectorEnd
    : ( ownedCrossMultiplicityMember )? ( name ( COLON_COLON_GT | REFERENCES ) )? ownedReferenceSubsetting
    ;

ownedCrossMultiplicityMember
    : ownedCrossMultiplicity
    ;

ownedCrossMultiplicity
    : ownedMultiplicity
    ;

bindingConnector
    : featurePrefix BINDING bindingConnectorDeclaration typeBody
    ;

bindingConnectorDeclaration
    : featureDeclaration ( OF connectorEndMember EQ connectorEndMember )?
    | ( ALL )? ( OF? connectorEndMember EQ connectorEndMember )?
    ;

succession
    : featurePrefix SUCCESSION successionDeclaration typeBody
    ;

successionDeclaration
    : featureDeclaration ( FIRST connectorEndMember THEN connectorEndMember )?
    | ( ALL )? ( FIRST? connectorEndMember THEN connectorEndMember )?
    ;

behavior
    : typePrefix BEHAVIOR classifierDeclaration typeBody
    ;

step
    : featurePrefix STEP featureDeclaration valuePart? typeBody
    ;

function
    : typePrefix FUNCTION classifierDeclaration functionBody
    ;

functionBody
    : SEMI
    | LBRACE functionBodyPart RBRACE
    ;

// Evidence: KerML `FunctionBodyPart` contains repeated type-body/return members followed by at most one result expression; the intermediate `definitionBodyItem` extension is not normative and makes `a.{ x }` exactly ambiguous.
// Reference: KerML FunctionBodyPart https://github.com/Systems-Modeling/SysML-v2-Release/blob/de1070ae8e79c21532b8004fc663d47b35d0e9fa/bnf/KerML-textual-bnf.kebnf#L879-L883; official Pilot counterpart https://github.com/Systems-Modeling/SysML-v2-Pilot-Implementation/blob/fa709f28dfd49dfdb7ee83e4e19da2f57e0eb3aa/org.omg.kerml.xtext/src/org/omg/kerml/xtext/KerML.xtext#L933-L941
functionBodyPart
    : ( typeBodyElement | returnFeatureMember )* ( resultExpressionMember )?
    ;

returnFeatureMember
    : memberPrefix RETURN featureElement
    ;

resultExpressionMember
    : memberPrefix ownedExpression
    ;

expression
    : featurePrefix EXPR featureDeclaration valuePart? functionBody
    ;

predicate
    : typePrefix PREDICATE classifierDeclaration functionBody
    ;

booleanExpression
    : featurePrefix BOOL featureDeclaration valuePart? functionBody
    ;

invariant
    : featurePrefix INV ( TRUE | FALSE )? featureDeclaration valuePart? functionBody
    ;

featureChainMember
    : qualifiedName ( DOT qualifiedName )*
    ;

interaction
    : typePrefix INTERACTION classifierDeclaration typeBody
    ;

flow
    : featurePrefix FLOW flowDeclaration typeBody
    ;

successionFlow
    : featurePrefix SUCCESSION FLOW flowDeclaration typeBody
    ;

flowDeclaration
    : featureDeclaration valuePart? ( OF payloadFeatureMember )? ( FROM flowEndMember TO flowEndMember )?
    | ( ALL )? flowEndMember TO flowEndMember
    | usageDeclaration? valuePart? ( OF flowPayloadFeatureMember )? ( FROM flowEndMember TO flowEndMember )?
    ;

payloadFeatureMember
    : payloadFeature
    ;

payloadFeature
    : identification payloadFeatureSpecializationPart valuePart?
    | identification valuePart
    | ownedFeatureTyping ( ownedMultiplicity )?
    | ownedMultiplicity ownedFeatureTyping
    | identification? payloadFeatureSpecializationPart valuePart?
    ;

payloadFeatureSpecializationPart
    : featureSpecialization+ multiplicityPart? featureSpecialization*
    | multiplicityPart featureSpecialization+
    ;

flowEndMember
    : flowEnd
    ;

flowEnd
    : qualifiedName ( DOT qualifiedName )*
    ;

valuePart
    : featureValue
    ;

featureValue
    : ( EQ | COLON_EQ | DEFAULT ( EQ | COLON_EQ )? ) ownedExpression
    ;

multiplicity
    : multiplicitySubset
    | multiplicityRange
    ;

multiplicitySubset
    : MULTIPLICITY identification? subsets typeBody
    ;

multiplicityRange
    : MULTIPLICITY identification? multiplicityBounds typeBody
    ;

ownedMultiplicity
    : ownedMultiplicityRange
    ;

ownedMultiplicityRange
    : multiplicityBounds
    ;

multiplicityBounds
    : LBRACK ( multiplicityExpressionMember DOT_DOT )? multiplicityExpressionMember RBRACK
    ;

multiplicityExpressionMember
    : ( literalExpression | featureReferenceExpression )
    ;

metaclass
    : typePrefix METACLASS classifierDeclaration typeBody
    ;

prefixMetadataAnnotation
    : HASH prefixMetadataFeature
    | HASH prefixMetadataUsage
    ;

prefixMetadataMember
    : HASH prefixMetadataFeature
    | HASH prefixMetadataUsage
    ;

prefixMetadataFeature
    : ownedFeatureTyping
    ;

metadataFeature
    : ( prefixMetadataMember )* ( AT_SIGN | METADATA ) metadataFeatureDeclaration ( ABOUT annotation ( COMMA annotation )* )? metadataBody
    ;

metadataFeatureDeclaration
    : ( identification? ( COLON | TYPED BY ) )? ownedFeatureTyping
    ;

metadataBody
    : SEMI
    | LBRACE ( metadataBodyElement )* RBRACE
    | LBRACE ( definitionMember | metadataBodyUsageMember | aliasMember | importRule )* RBRACE
    ;

metadataBodyElement
    : nonFeatureMember
    | metadataBodyFeatureMember
    | aliasMember
    | importRule
    ;

metadataBodyFeatureMember
    : metadataBodyFeature
    ;

metadataBodyFeature
    : FEATURE? ( COLON_GT_GT | REDEFINES )? ownedRedefinition featureSpecializationPart? valuePart? metadataBody
    ;

package
    : ( prefixMetadataMember )* packageDeclaration packageBody
    ;

libraryPackage
    : ( STANDARD )? LIBRARY ( prefixMetadataMember )* packageDeclaration packageBody
    ;

packageDeclaration
    : PACKAGE identification?
    ;

packageBody
    : SEMI
    | LBRACE packageBodyElement* RBRACE
    ;

elementFilterMember
    : memberPrefix FILTER ownedExpression SEMI
    ;

dependencyDeclaration
    : ( identification? FROM )? qualifiedName ( COMMA qualifiedName )* TO qualifiedName ( COMMA qualifiedName )*
    ;

annotatingMember
    : memberPrefix annotatingElement
    ;

packageBodyElement
    : packageMember
    | elementFilterMember
    | aliasMember
    | importRule
    ;

packageMember
    : memberPrefix ( definitionElement | usageElement )
    ;

definitionElement
    : package
    | libraryPackage
    | annotatingElement
    | dependency
    | attributeDefinition
    | enumerationDefinition
    | occurrenceDefinition
    | individualDefinition
    | itemDefinition
    | partDefinition
    | connectionDefinition
    | flowDefinition
    | interfaceDefinition
    | portDefinition
    | actionDefinition
    | calculationDefinition
    | stateDefinition
    | constraintDefinition
    | requirementDefinition
    | concernDefinition
    | caseDefinition
    | analysisCaseDefinition
    | verificationCaseDefinition
    | useCaseDefinition
    | viewDefinition
    | viewpointDefinition
    | renderingDefinition
    | metadataDefinition
    | allocationDefinition
    | extendedDefinition
    ;

usageElement
    : nonOccurrenceUsageElement
    | occurrenceUsageElement
    ;

basicDefinitionPrefix
    : ABSTRACT
    | VARIATION
    ;

definitionExtensionKeyword
    : prefixMetadataMember
    ;

definitionPrefix
    : basicDefinitionPrefix? definitionExtensionKeyword*
    ;

definition
    : definitionDeclaration definitionBody
    ;

definitionDeclaration
    : identification? subclassificationPart?
    ;

definitionBody
    : SEMI
    | LBRACE definitionBodyItem* RBRACE
    ;

definitionBodyItem
    : importRule
    | memberPrefix definitionBodyItemContent
    | ( sourceSuccessionMember )? memberPrefix endOccurrenceUsageElement
    | ( sourceSuccessionMember )? memberPrefix occurrenceUsageElement
    ;

// Factored dispatch: after memberPrefix is consumed, the next token
// (ALIAS, VARIANT, keyword, or identifier) unambiguously selects the branch.
// This reduces the SLL prediction DFA from 6 nullable-prefix alternatives to 3+4.
definitionBodyItemContent
    : ALIAS ( LT name GT )? ( name )? FOR qualifiedName relationshipBody
    | VARIANT variantUsageElement
    | definitionElement
    | nonOccurrenceUsageElement
    ;

definitionMember
    : memberPrefix definitionElement
    ;

variantUsageMember
    : memberPrefix VARIANT variantUsageElement
    ;

nonOccurrenceUsageMember
    : memberPrefix nonOccurrenceUsageElement
    ;

structureUsageMember
    : memberPrefix structureUsageElement
    ;

behaviorUsageMember
    : memberPrefix behaviorUsageElement
    ;

refPrefix
    : ( featureDirection )? ( DERIVED )? ( ABSTRACT | VARIATION )? ( CONSTANT )?
    ;

basicUsagePrefix
    : refPrefix ( REF )?
    ;

endUsagePrefix
    : END ownedCrossFeatureMember
    ;

usageExtensionKeyword
    : prefixMetadataMember
    ;

unextendedUsagePrefix
    : endUsagePrefix
    | basicUsagePrefix
    ;

usagePrefix
    : unextendedUsagePrefix usageExtensionKeyword*
    ;

usage
    : usageDeclaration? usageCompletion
    ;

usageDeclaration
    : identification featureSpecializationPart?
    | featureSpecializationPart
    ;

usageCompletion
    : valuePart? usageBody
    ;

usageBody
    : definitionBody
    ;

defaultReferenceUsage
    : refPrefix usageDeclaration usageCompletion
    ;

referenceUsage
    : ( endUsagePrefix | refPrefix ) REF usage
    ;

// Unnamed end feature with specialization (e.g., end :>> QualifiedName;)
// Handles end features in connection/flow/interface definition bodies
// where no name is given, only a redefines/subsets/typing.
endFeatureUsage
    : endUsagePrefix featureDeclaration usageCompletion
    ;

variantReference
    : ownedReferenceSubsetting featureSpecialization* usageBody
    ;

nonOccurrenceUsageElement
    : referenceUsage
    | endFeatureUsage
    | attributeUsage
    | enumerationUsage
    | bindingConnectorAsUsage
    | successionAsUsage
    | extendedUsage
    | defaultReferenceUsage
    ;

// end [multiplicity] <occurrence-keyword> — e.g. end [1] port p : P;
// The END keyword marks a feature as a connection/interface/flow endpoint.
// The optional multiplicity constrains the end feature cardinality.
endOccurrenceUsageElement
    : END ( name )? ( ownedCrossMultiplicityMember )? ( NONUNIQUE )? occurrenceUsageElement
    ;

occurrenceUsageElement
    : structureUsageElement
    | behaviorUsageElement
    ;

structureUsageElement
    : occurrenceUsage
    | individualUsage
    | portionUsage
    | eventOccurrenceUsage
    | itemUsage
    | partUsage
    | viewUsage
    | renderingUsage
    | portUsage
    | connectionUsage
    | interfaceUsage
    | allocationUsage
    | message
    | flowUsage
    | successionFlowUsage
    ;

behaviorUsageElement
    : actionUsage
    | calculationUsage
    | stateUsage
    | constraintUsage
    | requirementUsage
    | concernUsage
    | caseUsage
    | analysisCaseUsage
    | verificationCaseUsage
    | useCaseUsage
    | viewpointUsage
    | performActionUsage
    | exhibitStateUsage
    | includeUseCaseUsage
    | assertConstraintUsage
    | satisfyRequirementUsage
    ;

variantUsageElement
    : variantReference
    | referenceUsage
    | attributeUsage
    | bindingConnectorAsUsage
    | successionAsUsage
    | occurrenceUsage
    | individualUsage
    | portionUsage
    | eventOccurrenceUsage
    | itemUsage
    | partUsage
    | viewUsage
    | renderingUsage
    | portUsage
    | connectionUsage
    | interfaceUsage
    | allocationUsage
    | message
    | flowUsage
    | successionFlowUsage
    | behaviorUsageElement
    ;

subclassificationPart
    : ( COLON_GT | SPECIALIZES ) ownedSubclassification ( COMMA ownedSubclassification )*
    ;

attributeDefinition
    : definitionPrefix ATTRIBUTE DEF definition
    ;

attributeUsage
    : usagePrefix ATTRIBUTE usage
    ;

enumerationDefinition
    : definitionExtensionKeyword* ENUM DEF definitionDeclaration enumerationBody
    ;

enumerationBody
    : SEMI
    | LBRACE ( annotatingMember | enumerationUsageMember )* RBRACE
    ;

enumerationUsageMember
    : ( prefixMetadataMember )* memberPrefix enumeratedValue
    ;

enumeratedValue
    : ENUM? usage
    ;

enumerationUsage
    : usagePrefix ENUM usage
    ;

occurrenceDefinitionPrefix
    : basicDefinitionPrefix? ( INDIVIDUAL emptyMultiplicityMember )? definitionExtensionKeyword*
    ;

occurrenceDefinition
    : occurrenceDefinitionPrefix OCCURRENCE DEF definition
    ;

individualDefinition
    : basicDefinitionPrefix? INDIVIDUAL definitionExtensionKeyword* DEF definition emptyMultiplicityMember
    ;

emptyMultiplicityMember
    : emptyMultiplicity_
    ;

occurrenceUsagePrefix
    : basicUsagePrefix ( INDIVIDUAL )? ( portionKind )? usageExtensionKeyword*
    ;

occurrenceUsage
    : occurrenceUsagePrefix OCCURRENCE usage
    ;

individualUsage
    : basicUsagePrefix INDIVIDUAL usageExtensionKeyword* usage
    ;

portionUsage
    : basicUsagePrefix ( INDIVIDUAL )? portionKind usageExtensionKeyword* usage
    ;

portionKind
    : SNAPSHOT
    | TIMESLICE
    ;

eventOccurrenceUsage
    : occurrenceUsagePrefix EVENT ( ownedReferenceSubsetting featureSpecializationPart? | OCCURRENCE usageDeclaration? ) usageCompletion
    ;

sourceSuccessionMember
    : THEN sourceSuccession
    ;

sourceSuccession
    : sourceEndMember
    ;

sourceEndMember
    : sourceEnd
    ;

sourceEnd
    : ( ownedMultiplicity )?
    ;

itemDefinition
    : occurrenceDefinitionPrefix ITEM DEF definition
    ;

itemUsage
    : occurrenceUsagePrefix ITEM usage
    ;

partDefinition
    : occurrenceDefinitionPrefix PART DEF definition
    ;

partUsage
    : occurrenceUsagePrefix PART usage
    ;

portDefinition
    : definitionPrefix PORT DEF definition conjugatedPortDefinitionMember
    ;

conjugatedPortDefinitionMember
    : conjugatedPortDefinition
    ;

conjugatedPortDefinition
    : portConjugation
    ;

portUsage
    : occurrenceUsagePrefix PORT usage
    ;

conjugatedPortTyping
    : TILDE qualifiedName
    ;

connectionDefinition
    : occurrenceDefinitionPrefix CONNECTION DEF definition
    ;

connectionUsage
    : occurrenceUsagePrefix ( CONNECTION usageDeclaration? valuePart? ( CONNECT connectorPart )? | CONNECT connectorPart ) usageBody
    ;

connectorPart
    : binaryConnectorPart
    | naryConnectorPart
    ;

binaryConnectorPart
    : connectorEndMember TO connectorEndMember
    ;

naryConnectorPart
    : LPAREN connectorEndMember COMMA connectorEndMember ( COMMA connectorEndMember )* RPAREN
    ;

bindingConnectorAsUsage
    : usagePrefix ( BINDING usageDeclaration? )? BIND connectorEndMember EQ connectorEndMember usageBody
    ;

successionAsUsage
    : usagePrefix ( SUCCESSION usageDeclaration? )? FIRST connectorEndMember THEN connectorEndMember usageBody
    ;

interfaceDefinition
    : occurrenceDefinitionPrefix INTERFACE DEF definitionDeclaration interfaceBody
    ;

interfaceBody
    : SEMI
    | LBRACE interfaceBodyItem* RBRACE
    ;

interfaceBodyItem
    : definitionMember
    | variantUsageMember
    | interfaceNonOccurrenceUsageMember
    | ( sourceSuccessionMember )? interfaceOccurrenceUsageMember
    | aliasMember
    | importRule
    ;

interfaceNonOccurrenceUsageMember
    : memberPrefix interfaceNonOccurrenceUsageElement
    ;

interfaceNonOccurrenceUsageElement
    : referenceUsage
    | attributeUsage
    | enumerationUsage
    | bindingConnectorAsUsage
    | successionAsUsage
    ;

interfaceOccurrenceUsageMember
    : memberPrefix interfaceOccurrenceUsageElement
    ;

interfaceOccurrenceUsageElement
    : defaultInterfaceEnd
    | endOccurrenceUsageElement
    | structureUsageElement
    | behaviorUsageElement
    ;

defaultInterfaceEnd
    : END usage
    ;

interfaceUsage
    : occurrenceUsagePrefix INTERFACE interfaceUsageDeclaration interfaceBody
    ;

interfaceUsageDeclaration
    : usageDeclaration? valuePart? ( CONNECT interfacePart )?
    | interfacePart
    ;

interfacePart
    : binaryInterfacePart
    | naryInterfacePart
    ;

binaryInterfacePart
    : interfaceEndMember TO interfaceEndMember
    ;

naryInterfacePart
    : LPAREN interfaceEndMember COMMA interfaceEndMember ( COMMA interfaceEndMember )* RPAREN
    ;

interfaceEndMember
    : interfaceEnd
    ;

interfaceEnd
    : ( ownedCrossMultiplicityMember )? ( name ( COLON_COLON_GT | REFERENCES ) )? ownedReferenceSubsetting
    ;

allocationDefinition
    : occurrenceDefinitionPrefix ALLOCATION DEF definition
    ;

allocationUsage
    : occurrenceUsagePrefix allocationUsageDeclaration usageBody
    ;

allocationUsageDeclaration
    : ALLOCATION usageDeclaration? ( ALLOCATE connectorPart )?
    | ALLOCATE connectorPart
    ;

flowDefinition
    : occurrenceDefinitionPrefix FLOW DEF definition
    ;

message
    : occurrenceUsagePrefix MESSAGE messageDeclaration definitionBody
    ;

messageDeclaration
    : usageDeclaration? valuePart? ( OF flowPayloadFeatureMember )? ( FROM messageEventMember TO messageEventMember )?
    | messageEventMember TO messageEventMember
    ;

messageEventMember
    : messageEvent
    ;

messageEvent
    : ownedReferenceSubsetting
    ;

flowUsage
    : occurrenceUsagePrefix FLOW flowDeclaration definitionBody
    ;

successionFlowUsage
    : occurrenceUsagePrefix SUCCESSION FLOW flowDeclaration definitionBody
    ;

flowPayloadFeatureMember
    : flowPayloadFeature
    ;

flowPayloadFeature
    : payloadFeature
    ;

actionDefinition
    : occurrenceDefinitionPrefix ACTION DEF definitionDeclaration actionBody
    ;

actionBody
    : SEMI
    | LBRACE actionBodyItem* RBRACE
    ;

actionBodyItem
    : nonBehaviorBodyItem
    | initialNodeMember ( actionTargetSuccessionMember )*
    | ( sourceSuccessionMember )? actionBehaviorMember ( actionTargetSuccessionMember )*
    | guardedSuccessionMember
    ;

nonBehaviorBodyItem
    : importRule
    | aliasMember
    | definitionMember
    | variantUsageMember
    | nonOccurrenceUsageMember
    | ( sourceSuccessionMember )? structureUsageMember
    ;

actionBehaviorMember
    : actionNodeMember
    | behaviorUsageMember
    ;

initialNodeMember
    : memberPrefix FIRST qualifiedName relationshipBody
    ;

actionNodeMember
    : memberPrefix actionNode
    ;

actionTargetSuccessionMember
    : memberPrefix actionTargetSuccession
    ;

guardedSuccessionMember
    : memberPrefix guardedSuccession
    ;

actionUsage
    : occurrenceUsagePrefix ACTION actionUsageDeclaration actionBody
    ;

actionUsageDeclaration
    : usageDeclaration? valuePart?
    ;

performActionUsage
    : occurrenceUsagePrefix PERFORM performActionUsageDeclaration actionBody
    ;

performActionUsageDeclaration
    : ( ownedReferenceSubsetting featureSpecializationPart? | ACTION usageDeclaration? ) valuePart?
    ;

actionNode
    : controlNode
    | sendNode
    | acceptNode
    | assignmentNode
    | terminateNode
    | ifNode
    | whileLoopNode
    | forLoopNode
    ;

actionNodeUsageDeclaration
    : ACTION usageDeclaration?
    ;

actionNodePrefix
    : occurrenceUsagePrefix actionNodeUsageDeclaration?
    ;

controlNode
    : mergeNode
    | decisionNode
    | joinNode
    | forkNode
    ;

controlNodePrefix
    : refPrefix ( INDIVIDUAL )? ( portionKind )? usageExtensionKeyword*
    ;

mergeNode
    : controlNodePrefix MERGE usageDeclaration? actionBody
    ;

decisionNode
    : controlNodePrefix DECIDE usageDeclaration? actionBody
    ;

joinNode
    : controlNodePrefix JOIN usageDeclaration? actionBody
    ;

forkNode
    : controlNodePrefix FORK usageDeclaration? actionBody
    ;

acceptNode
    : occurrenceUsagePrefix acceptNodeDeclaration actionBody
    ;

acceptNodeDeclaration
    : actionNodeUsageDeclaration? ACCEPT acceptParameterPart
    ;

acceptParameterPart
    : payloadParameterMember ( VIA nodeParameterMember )?
    ;

payloadParameterMember
    : payloadParameter
    ;

payloadParameter
    : payloadFeature
    | identification? payloadFeatureSpecializationPart? triggerValuePart
    ;

triggerValuePart
    : triggerFeatureValue
    ;

triggerFeatureValue
    : triggerExpression
    ;

triggerExpression
    : ( AT | AFTER ) argumentMember
    | WHEN argumentExpressionMember
    ;

sendNode
    : occurrenceUsagePrefix ( actionNodeUsageDeclaration | actionUsageDeclaration ) SEND ( nodeParameterMember senderReceiverPart? | emptyParameterMember senderReceiverPart? ) actionBody
    ;

sendNodeDeclaration
    : actionNodeUsageDeclaration? SEND nodeParameterMember senderReceiverPart?
    ;

senderReceiverPart
    : VIA nodeParameterMember ( TO nodeParameterMember )?
    | emptyParameterMember TO nodeParameterMember
    ;

nodeParameterMember
    : nodeParameter
    ;

nodeParameter
    : featureBinding
    ;

featureBinding
    : ownedExpression
    ;

emptyParameterMember
    : emptyUsage_
    ;

assignmentNode
    : occurrenceUsagePrefix assignmentNodeDeclaration actionBody
    ;

assignmentNodeDeclaration
    : ( actionNodeUsageDeclaration )? ASSIGN assignmentTargetMember featureChainMember COLON_EQ nodeParameterMember
    ;

assignmentTargetMember
    : assignmentTargetParameter
    ;

assignmentTargetParameter
    : ( assignmentTargetBinding DOT )?
    ;

assignmentTargetBinding
    : nonFeatureChainPrimaryExpression
    ;

terminateNode
    : occurrenceUsagePrefix actionNodeUsageDeclaration? TERMINATE ( nodeParameterMember )? actionBody
    ;

ifNode
    : actionNodePrefix IF expressionParameterMember actionBodyParameterMember ( ELSE ( actionBodyParameterMember | ifNodeParameterMember ) )?
    ;

expressionParameterMember
    : ownedExpression
    ;

actionBodyParameterMember
    : actionBodyParameter
    ;

actionBodyParameter
    : ( ACTION usageDeclaration? )? LBRACE actionBodyItem* RBRACE
    ;

ifNodeParameterMember
    : ifNode
    ;

whileLoopNode
    : actionNodePrefix ( WHILE expressionParameterMember | LOOP emptyParameterMember ) actionBodyParameterMember ( UNTIL expressionParameterMember SEMI )?
    ;

forLoopNode
    : actionNodePrefix FOR forVariableDeclarationMember IN nodeParameterMember actionBodyParameterMember
    ;

forVariableDeclarationMember
    : usageDeclaration?
    ;

actionTargetSuccession
    : ( targetSuccession | guardedTargetSuccession | defaultTargetSuccession ) usageBody
    ;

targetSuccession
    : sourceEndMember THEN connectorEndMember
    ;

guardedTargetSuccession
    : guardExpressionMember THEN transitionSuccessionMember
    ;

defaultTargetSuccession
    : ELSE transitionSuccessionMember
    ;

guardedSuccession
    : ( SUCCESSION usageDeclaration? )? FIRST featureChainMember guardExpressionMember THEN transitionSuccessionMember usageBody
    ;

stateDefinition
    : occurrenceDefinitionPrefix STATE DEF definitionDeclaration stateDefBody
    ;

stateDefBody
    : SEMI
    | ( PARALLEL )? LBRACE stateBodyItem* RBRACE
    ;

stateBodyItem
    : nonBehaviorBodyItem
    | ( sourceSuccessionMember )? behaviorUsageMember ( targetTransitionUsageMember )*
    | transitionUsageMember
    | entryActionMember ( entryTransitionMember )*
    | doActionMember
    | exitActionMember
    ;

entryActionMember
    : memberPrefix ENTRY stateActionUsage
    ;

doActionMember
    : memberPrefix DO stateActionUsage
    ;

exitActionMember
    : memberPrefix EXIT stateActionUsage
    ;

entryTransitionMember
    : memberPrefix ( guardedTargetSuccession | THEN transitionSuccessionMember ) SEMI
    ;

stateActionUsage
    : emptyActionUsage_ SEMI
    | statePerformActionUsage
    | stateAcceptActionUsage
    | stateSendActionUsage
    | stateAssignmentActionUsage
    ;

statePerformActionUsage
    : performActionUsageDeclaration actionBody
    ;

stateAcceptActionUsage
    : acceptNodeDeclaration actionBody
    ;

stateSendActionUsage
    : sendNodeDeclaration actionBody
    ;

stateAssignmentActionUsage
    : assignmentNodeDeclaration actionBody
    ;

transitionUsageMember
    : memberPrefix transitionUsage
    ;

targetTransitionUsageMember
    : memberPrefix targetTransitionUsage
    ;

stateUsage
    : occurrenceUsagePrefix STATE actionUsageDeclaration stateUsageBody
    ;

stateUsageBody
    : SEMI
    | ( PARALLEL )? LBRACE stateBodyItem* RBRACE
    ;

exhibitStateUsage
    : occurrenceUsagePrefix EXHIBIT ( ownedReferenceSubsetting featureSpecializationPart? | STATE usageDeclaration? ) valuePart? stateUsageBody
    ;

transitionUsage
    : TRANSITION ( usageDeclaration? FIRST )? featureChainMember emptyParameterMember ( emptyParameterMember triggerActionMember )? ( guardExpressionMember )? ( effectBehaviorMember )? THEN transitionSuccessionMember actionBody
    ;

targetTransitionUsage
    : emptyParameterMember ( TRANSITION ( emptyParameterMember triggerActionMember )? ( guardExpressionMember )? ( effectBehaviorMember )? | emptyParameterMember triggerActionMember ( guardExpressionMember )? ( effectBehaviorMember )? | guardExpressionMember ( effectBehaviorMember )? )? THEN transitionSuccessionMember actionBody
    ;

triggerActionMember
    : ACCEPT triggerAction
    ;

triggerAction
    : acceptParameterPart
    ;

guardExpressionMember
    : IF ownedExpression
    ;

effectBehaviorMember
    : DO effectBehaviorUsage
    ;

effectBehaviorUsage
    : emptyActionUsage_
    | transitionPerformActionUsage
    | transitionAcceptActionUsage
    | transitionSendActionUsage
    | transitionAssignmentActionUsage
    ;

transitionPerformActionUsage
    : performActionUsageDeclaration ( LBRACE actionBodyItem* RBRACE )?
    ;

transitionAcceptActionUsage
    : acceptNodeDeclaration ( LBRACE actionBodyItem* RBRACE )?
    ;

transitionSendActionUsage
    : sendNodeDeclaration ( LBRACE actionBodyItem* RBRACE )?
    ;

transitionAssignmentActionUsage
    : assignmentNodeDeclaration ( LBRACE actionBodyItem* RBRACE )?
    ;

transitionSuccessionMember
    : transitionSuccession
    ;

transitionSuccession
    : emptyEndMember connectorEndMember
    ;

emptyEndMember
    : emptyFeature_
    ;

calculationDefinition
    : occurrenceDefinitionPrefix CALC DEF definitionDeclaration calculationBody
    ;

calculationUsage
    : occurrenceUsagePrefix CALC actionUsageDeclaration calculationBody
    ;

calculationBody
    : SEMI
    | LBRACE calculationBodyPart RBRACE
    ;

calculationBodyPart
    : calculationBodyItem* ( resultExpressionMember )?
    ;

calculationBodyItem
    : actionBodyItem
    | returnParameterMember
    ;

returnParameterMember
    : memberPrefix RETURN usageElement
    ;

constraintDefinition
    : occurrenceDefinitionPrefix CONSTRAINT DEF definitionDeclaration calculationBody
    ;

constraintUsage
    : occurrenceUsagePrefix CONSTRAINT constraintUsageDeclaration calculationBody
    ;

assertConstraintUsage
    : occurrenceUsagePrefix ASSERT ( NOT )? ( ownedReferenceSubsetting featureSpecializationPart? | CONSTRAINT constraintUsageDeclaration ) calculationBody
    ;

constraintUsageDeclaration
    : usageDeclaration? valuePart?
    ;

requirementDefinition
    : occurrenceDefinitionPrefix REQUIREMENT DEF definitionDeclaration requirementBody
    ;

requirementBody
    : SEMI
    | LBRACE requirementBodyItem* RBRACE
    ;

requirementBodyItem
    : definitionBodyItem
    | subjectMember
    | requirementConstraintMember
    | framedConcernMember
    | requirementVerificationMember
    | actorMember
    | stakeholderMember
    ;

subjectMember
    : memberPrefix subjectUsage
    ;

subjectUsage
    : SUBJECT usageExtensionKeyword* usage
    ;

requirementConstraintMember
    : memberPrefix requirementKind requirementConstraintUsage
    ;

requirementKind
    : ASSUME
    | REQUIRE
    ;

requirementConstraintUsage
    : ownedReferenceSubsetting featureSpecializationPart? requirementBody
    | ( usageExtensionKeyword* CONSTRAINT | usageExtensionKeyword+ ) constraintUsageDeclaration calculationBody
    ;

framedConcernMember
    : memberPrefix FRAME framedConcernUsage
    ;

framedConcernUsage
    : ownedReferenceSubsetting featureSpecializationPart? requirementBody
    | ( usageExtensionKeyword* CONCERN | usageExtensionKeyword+ ) constraintUsageDeclaration requirementBody
    ;

actorMember
    : memberPrefix actorUsage
    ;

actorUsage
    : ACTOR usageExtensionKeyword* usage
    ;

stakeholderMember
    : memberPrefix stakeholderUsage
    ;

stakeholderUsage
    : STAKEHOLDER usageExtensionKeyword* usage
    ;

requirementUsage
    : occurrenceUsagePrefix REQUIREMENT constraintUsageDeclaration requirementBody
    ;

satisfyRequirementUsage
    : occurrenceUsagePrefix ( ASSERT ( NOT )? | NOT )? SATISFY ( ownedReferenceSubsetting featureSpecializationPart? | REQUIREMENT usageDeclaration? ) valuePart? ( BY satisfactionSubjectMember )? requirementBody
    ;

satisfactionSubjectMember
    : satisfactionParameter
    ;

satisfactionParameter
    : satisfactionFeatureValue
    ;

satisfactionFeatureValue
    : satisfactionReferenceExpression
    ;

satisfactionReferenceExpression
    : featureChainMember
    ;

concernDefinition
    : occurrenceDefinitionPrefix CONCERN DEF definitionDeclaration requirementBody
    ;

concernUsage
    : occurrenceUsagePrefix CONCERN constraintUsageDeclaration requirementBody
    ;

caseDefinition
    : occurrenceDefinitionPrefix CASE DEF definitionDeclaration caseBody
    ;

caseUsage
    : occurrenceUsagePrefix CASE constraintUsageDeclaration caseBody
    ;

caseBody
    : SEMI
    | LBRACE caseBodyItem* ( resultExpressionMember )? RBRACE
    ;

caseBodyItem
    : actionBodyItem
    | returnParameterMember
    | subjectMember
    | actorMember
    | objectiveMember
    ;

objectiveMember
    : memberPrefix OBJECTIVE objectiveRequirementUsage
    ;

objectiveRequirementUsage
    : usageExtensionKeyword* constraintUsageDeclaration requirementBody
    ;

analysisCaseDefinition
    : occurrenceDefinitionPrefix ANALYSIS DEF definitionDeclaration caseBody
    ;

analysisCaseUsage
    : occurrenceUsagePrefix ANALYSIS constraintUsageDeclaration caseBody
    ;

verificationCaseDefinition
    : occurrenceDefinitionPrefix VERIFICATION DEF definitionDeclaration caseBody
    ;

verificationCaseUsage
    : occurrenceUsagePrefix VERIFICATION constraintUsageDeclaration caseBody
    ;

requirementVerificationMember
    : memberPrefix VERIFY requirementVerificationUsage
    ;

requirementVerificationUsage
    : ownedReferenceSubsetting featureSpecialization* requirementBody
    | ( usageExtensionKeyword* REQUIREMENT | usageExtensionKeyword+ ) constraintUsageDeclaration requirementBody
    ;

useCaseDefinition
    : occurrenceDefinitionPrefix USE CASE DEF definitionDeclaration caseBody
    ;

useCaseUsage
    : occurrenceUsagePrefix USE CASE constraintUsageDeclaration caseBody
    ;

includeUseCaseUsage
    : occurrenceUsagePrefix INCLUDE ( ownedReferenceSubsetting featureSpecializationPart? | USE CASE usageDeclaration? ) valuePart? caseBody
    ;

viewDefinition
    : occurrenceDefinitionPrefix VIEW DEF definitionDeclaration viewDefinitionBody
    ;

viewDefinitionBody
    : SEMI
    | LBRACE viewDefinitionBodyItem* RBRACE
    ;

viewDefinitionBodyItem
    : definitionBodyItem
    | elementFilterMember
    | viewRenderingMember
    ;

viewRenderingMember
    : memberPrefix RENDER viewRenderingUsage
    ;

viewRenderingUsage
    : ownedReferenceSubsetting featureSpecializationPart? usageBody
    | ( usageExtensionKeyword* RENDERING | usageExtensionKeyword+ ) usage
    ;

viewUsage
    : occurrenceUsagePrefix VIEW usageDeclaration? valuePart? viewBody
    ;

viewBody
    : SEMI
    | LBRACE viewBodyItem* RBRACE
    ;

viewBodyItem
    : definitionBodyItem
    | elementFilterMember
    | viewRenderingMember
    | expose
    ;

expose
    : EXPOSE ( membershipExpose | namespaceExpose ) relationshipBody
    ;

membershipExpose
    : membershipImport
    ;

namespaceExpose
    : namespaceImport
    ;

viewpointDefinition
    : occurrenceDefinitionPrefix VIEWPOINT DEF definitionDeclaration requirementBody
    ;

viewpointUsage
    : occurrenceUsagePrefix VIEWPOINT constraintUsageDeclaration requirementBody
    ;

renderingDefinition
    : occurrenceDefinitionPrefix RENDERING DEF definition
    ;

renderingUsage
    : occurrenceUsagePrefix RENDERING usage
    ;

metadataDefinition
    : ( ABSTRACT )? definitionExtensionKeyword* METADATA DEF definition
    ;

prefixMetadataUsage
    : ownedFeatureTyping
    ;

metadataBodyUsageMember
    : metadataBodyUsage
    ;

metadataBodyUsage
    : REF? ( COLON_GT_GT | REDEFINES )? ownedRedefinition featureSpecializationPart? valuePart? metadataBody
    ;

extendedDefinition
    : basicDefinitionPrefix? definitionExtensionKeyword+ DEF definition
    ;

extendedUsage
    : unextendedUsagePrefix usageExtensionKeyword+ usage
    ;

filterPackageImportDeclaration
    : membershipImport
    | namespaceImportDirect
    ;

namespaceImportDirect
    : qualifiedName COLON_COLON STAR ( COLON_COLON STAR_STAR )?
    ;

// ===== Stub rules for undefined references =====
// These rules are referenced in the spec but not fully defined.
// They need manual review and completion.

emptyActionUsage_
    : /* epsilon */
    ;

emptyFeature_
    : /* epsilon */
    ;

emptyMultiplicity_
    : /* epsilon */
    ;

emptyUsage_
    : /* epsilon */
    ;

nonFeatureChainPrimaryExpression
    : IDENTIFIER  /* TODO: stub for nonFeatureChainPrimaryExpression */
    ;

portConjugation
    : /* epsilon */
    ;
