import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.antlr.v4.runtime.BaseErrorListener;
import org.antlr.v4.runtime.CharStreams;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.Parser;
import org.antlr.v4.runtime.Recognizer;
import org.antlr.v4.runtime.RecognitionException;
import org.antlr.v4.runtime.Token;
import org.antlr.v4.runtime.atn.ATNConfigSet;
import org.antlr.v4.runtime.atn.PredictionMode;
import org.antlr.v4.runtime.dfa.DFA;
import org.antlr.v4.runtime.tree.ParseTree;
import org.antlr.v4.runtime.tree.TerminalNode;

/** Deterministic grammar-level regression tests for the expression rules. */
public final class ExpressionGrammarTest {
    private static final class ErrorCollector extends BaseErrorListener {
        private final List<String> messages = new ArrayList<>();
        private int ambiguities;

        @Override
        public void syntaxError(
                Recognizer<?, ?> recognizer,
                Object offendingSymbol,
                int line,
                int charPositionInLine,
                String message,
                RecognitionException exception) {
            messages.add(line + ":" + charPositionInLine + ":" + message);
        }

        @Override
        public void reportAmbiguity(
                Parser recognizer,
                DFA dfa,
                int startIndex,
                int stopIndex,
                boolean exact,
                java.util.BitSet ambigAlts,
                ATNConfigSet configs) {
            ambiguities++;
            messages.add("ambiguity " + startIndex + "-" + stopIndex);
        }
    }

    private static final class TestCase {
        private final String input;
        private final boolean valid;
        private final Map<String, String> operatorRules = new HashMap<>();
        private final Map<String, Boolean> sameParent = new HashMap<>();
        private String requiredRule;
        private String outermostOperator;

        private TestCase(String input, boolean valid) {
            this.input = input;
            this.valid = valid;
        }

        private TestCase operator(String token, String rule) {
            operatorRules.put(token, rule + "Context");
            return this;
        }

        private TestCase leftAssociative(String token) {
            sameParent.put(token, true);
            return this;
        }

        private TestCase rightAssociative(String token) {
            sameParent.put(token, false);
            return this;
        }

        private TestCase requiresRule(String rule) {
            requiredRule = rule + "Context";
            return this;
        }

        private TestCase outermost(String token) {
            outermostOperator = token;
            return this;
        }
    }

    private static TestCase valid(String input) {
        return new TestCase(input, true);
    }

    private static TestCase invalid(String input) {
        return new TestCase(input, false);
    }

    private static List<TestCase> cases() {
        List<TestCase> cases = new ArrayList<>();

        cases.add(valid("a + b * c").operator("+", "AdditiveExpression").operator("*", "MultiplicativeExpression").outermost("+"));
        cases.add(valid("a * b + c").operator("*", "MultiplicativeExpression").operator("+", "AdditiveExpression").outermost("+"));
        cases.add(valid("a * b ** c").operator("*", "MultiplicativeExpression").operator("**", "ExponentiationExpression").outermost("*"));
        cases.add(valid("a ** b * c").operator("**", "ExponentiationExpression").operator("*", "MultiplicativeExpression").outermost("*"));
        cases.add(valid("a .. b + c").operator("..", "RangeExpression").operator("+", "AdditiveExpression").outermost(".."));
        cases.add(valid("a + b .. c").operator("+", "AdditiveExpression").operator("..", "RangeExpression").outermost(".."));
        cases.add(valid("a .. b < c").operator("..", "RangeExpression").operator("<", "RelationalExpression").outermost("<"));
        cases.add(valid("a < b == c").operator("<", "RelationalExpression").operator("==", "EqualityExpression").outermost("=="));
        cases.add(valid("a == b < c").operator("==", "EqualityExpression").operator("<", "RelationalExpression").outermost("=="));
        cases.add(
                valid("a < b istype T == c")
                        .operator("<", "RelationalExpression")
                        .operator("istype", "ClassificationExpression")
                        .operator("==", "EqualityExpression"));
        cases.add(valid("a == b istype T").operator("==", "EqualityExpression").operator("istype", "ClassificationExpression"));
        cases.add(
                valid("a == b & c xor d | e implies f ?? g")
                        .operator("==", "EqualityExpression")
                        .operator("&", "AndExpression")
                        .operator("xor", "XorExpression")
                        .operator("|", "OrExpression")
                        .operator("implies", "ImpliesExpression")
                        .operator("??", "NullCoalescingExpression"));
        cases.add(valid("a ?? b implies c").operator("??", "NullCoalescingExpression").operator("implies", "ImpliesExpression"));
        cases.add(valid("a implies b ?? c").operator("implies", "ImpliesExpression").operator("??", "NullCoalescingExpression"));
        cases.add(valid("a or b and c").operator("or", "OrExpression").operator("and", "AndExpression"));
        cases.add(valid("a and b or c").operator("and", "AndExpression").operator("or", "OrExpression"));
        cases.add(valid("a xor b & c").operator("xor", "XorExpression").operator("&", "AndExpression"));
        cases.add(valid("a & b xor c").operator("&", "AndExpression").operator("xor", "XorExpression"));
        cases.add(
                valid("a and b & c")
                        .operator("and", "AndExpression")
                        .operator("&", "AndExpression"));
        cases.add(
                valid("a or b | c")
                        .operator("or", "OrExpression")
                        .operator("|", "OrExpression"));
        cases.add(valid("a ?? b ?? c").operator("??", "NullCoalescingExpression").leftAssociative("??"));
        cases.add(valid("a implies b implies c").operator("implies", "ImpliesExpression").leftAssociative("implies"));
        cases.add(valid("a or b or c").operator("or", "OrExpression").leftAssociative("or"));
        cases.add(valid("a xor b xor c").operator("xor", "XorExpression").leftAssociative("xor"));
        cases.add(valid("a and b and c").operator("and", "AndExpression").leftAssociative("and"));
        cases.add(valid("a == b == c").operator("==", "EqualityExpression").leftAssociative("=="));
        cases.add(valid("a < b < c").operator("<", "RelationalExpression").leftAssociative("<"));
        cases.add(valid("a .. b .. c").operator("..", "RangeExpression").leftAssociative(".."));
        cases.add(valid("a + b + c").operator("+", "AdditiveExpression").leftAssociative("+"));
        cases.add(valid("a * b * c").operator("*", "MultiplicativeExpression").leftAssociative("*"));
        cases.add(valid("a / b / c").operator("/", "MultiplicativeExpression").leftAssociative("/"));
        cases.add(valid("a % b % c").operator("%", "MultiplicativeExpression").leftAssociative("%"));
        cases.add(
                valid("a - b - c")
                        .operator("-", "AdditiveExpression")
                        .leftAssociative("-"));
        cases.add(
                valid("a ** b ** c")
                        .operator("**", "ExponentiationExpression")
                        .rightAssociative("**"));
        cases.add(
                valid("a ^ b ^ c")
                        .operator("^", "ExponentiationExpression")
                        .rightAssociative("^"));
        cases.add(
                valid("a ** b ^ c")
                        .operator("**", "ExponentiationExpression")
                        .operator("^", "ExponentiationExpression"));
        cases.add(
                valid("a != b === c")
                        .operator("!=", "EqualityExpression")
                        .operator("===", "EqualityExpression"));
        cases.add(
                valid("a <= b >= c")
                        .operator("<=", "RelationalExpression")
                        .operator(">=", "RelationalExpression"));
        cases.add(
                valid("a & b and c")
                        .operator("&", "AndExpression")
                        .operator("and", "AndExpression"));
        cases.add(
                valid("a | b or c")
                        .operator("|", "OrExpression")
                        .operator("or", "OrExpression"));
        cases.add(
                valid("if a + b ? c * d else e ** f")
                        .operator("+", "AdditiveExpression")
                        .operator("*", "MultiplicativeExpression")
                        .operator("**", "ExponentiationExpression"));
        cases.add(valid("if a ? b else c + d").operator("+", "AdditiveExpression"));
        cases.add(valid("if a ? b else if c ? d else e"));
        cases.add(valid("-a.b"));
        cases.add(valid("not -a"));
        cases.add(valid("+a"));
        cases.add(valid("~a"));
        cases.add(valid("-a ** b").operator("-", "UnaryExpression").operator("**", "ExponentiationExpression"));
        cases.add(valid("a ** -b").operator("**", "ExponentiationExpression").operator("-", "UnaryExpression"));
        cases.add(valid("all T + b").operator("+", "AdditiveExpression"));
        cases.add(valid("a + b istype T").operator("+", "AdditiveExpression").operator("istype", "ClassificationExpression"));
        cases.add(valid("(a istype T) + b").operator("istype", "ClassificationExpression").operator("+", "AdditiveExpression"));
        cases.add(valid("a istype T == b").operator("istype", "ClassificationExpression").operator("==", "EqualityExpression"));
        cases.add(valid("a as T").operator("as", "ClassificationExpression"));
        cases.add(valid("a hastype T").operator("hastype", "ClassificationExpression"));
        cases.add(valid("a @ T == b").operator("@", "ClassificationExpression").operator("==", "EqualityExpression"));
        cases.add(valid("a @@ T == b").operator("@@", "ClassificationExpression").operator("==", "EqualityExpression"));
        cases.add(valid("a meta T == b").operator("meta", "ClassificationExpression").operator("==", "EqualityExpression"));
        cases.add(valid("istype T"));
        cases.add(valid("hastype T"));
        cases.add(valid("@ T"));
        cases.add(valid("as T"));
        cases.add(valid("a @ T"));
        cases.add(valid("a @@ T"));
        cases.add(valid("a meta T"));
        cases.add(valid("a::b @@ T"));
        cases.add(valid("a.metadata @ T"));
        cases.add(valid("a.metadata as T"));
        cases.add(valid("(as T).isMandatory"));
        cases.add(valid("a.{}").requiresRule("BodyExpression"));
        cases.add(valid("a.{ x }").requiresRule("BodyExpression"));
        cases.add(valid("a.?{ x }").requiresRule("BodyExpression"));
        cases.add(valid("a.;").requiresRule("BodyExpression"));
        cases.add(valid("a.?;").requiresRule("BodyExpression"));
        cases.add(valid("a->F;"));
        cases.add(valid("a->F { x }").requiresRule("BodyExpression"));
        cases.add(valid("a.{ private attribute x := y; x }"));
        cases.add(valid("a.?{}"));
        cases.add(valid("a.{;}").requiresRule("BodyExpression"));
        cases.add(valid("a.{x;;}").requiresRule("BodyExpression"));
        cases.add(valid("a.{x; ;}").requiresRule("BodyExpression"));
        cases.add(valid("a.{x ; ;}").requiresRule("BodyExpression"));
        cases.add(valid("a.{y ; ;}").requiresRule("BodyExpression"));
        // Official KEBNF/Pilot keep REGULAR_COMMENT visible as a model-owned
        // comment body; it is not a base-expression operand. ML_NOTE is hidden
        // trivia only when it is recognized as a multiline note.
        cases.add(valid("a.{/* c */}"));
        cases.add(valid("a.{x; /* c */}"));
        cases.add(valid("a.?{/* c */}"));
        cases.add(valid("a->f{/* c */}"));
        cases.add(valid("a.{\n//* c */\n}"));
        cases.add(invalid("a.{//* c */}"));
        cases.add(invalid("a.{//* c */}\n"));
        cases.add(invalid("(/* c */)"));
        cases.add(valid("a->F()"));
        cases.add(valid("a.f()").requiresRule("InvocationExpression"));
        cases.add(valid("a.f.g()"));
        cases.add(valid("a().b"));
        cases.add(valid("a.f().g"));
        cases.add(valid("a[1]"));
        cases.add(valid("a#(1)"));
        cases.add(valid("a(x = b)"));
        cases.add(valid("a->F.g()"));
        cases.add(valid("a->F.g {}"));
        cases.add(valid("a->F {}"));
        cases.add(valid("a->F g"));
        cases.add(valid("a->F g + h").operator("+", "AdditiveExpression"));
        cases.add(valid("a.b.c"));
        cases.add(valid("a.metadata").requiresRule("MetadataAccessExpression"));
        cases.add(valid("a.b[1,].d"));
        cases.add(valid("a#(1,)"));
        cases.add(valid("(a,)"));
        cases.add(valid("()"));
        cases.add(valid("a()"));
        cases.add(valid("new T()"));
        cases.add(valid("new A.B()"));
        cases.add(invalid("a istype T + b"));
        cases.add(invalid("a istype T < b"));
        cases.add(invalid("a as T < b"));
        cases.add(invalid("a as T + b"));
        cases.add(invalid("a istype T as U"));
        cases.add(invalid("@@ T"));
        cases.add(invalid("meta T"));
        cases.add(invalid("a.metadata @@ T"));
        cases.add(invalid("a.metadata meta T"));
        cases.add(invalid("a + b @@ T"));
        cases.add(invalid("a @@ T + b"));
        cases.add(invalid("a meta T < b"));
        cases.add(invalid("a[]"));
        cases.add(invalid("a#()"));
        cases.add(invalid("a(b)(c)"));
        cases.add(invalid("a()()"));
        cases.add(invalid("a.f()()"));
        cases.add(invalid("a.metadata()"));
        cases.add(invalid("a->F"));
        cases.add(invalid("a->F.g"));
        cases.add(invalid("a + b c"));
        // KerML Pilot Name is ID | UNRESTRICTED_NAME. These reserved words
        // must not be admitted through the compatibility name alternatives.
        cases.add(invalid("language"));
        cases.add(invalid("locale"));
        cases.add(invalid("crosses"));
        cases.add(valid("typed"));
        // The abstract KEBNF derives these through OwnedExpression operands,
        // but the released Pilot's concrete precedence grammar rejects them.
        // Keep that implementation boundary explicit until a deterministic
        // recursive-operand grammar is available.
        cases.add(invalid("a + if b ? c else d"));
        cases.add(invalid("-if b ? c else d"));
        cases.add(invalid("a ** if b ? c else d"));
        cases.add(invalid("a ?? if b ? c else d"));
        cases.add(invalid("a.{;;}"));
        cases.add(invalid("a.{; x}"));
        cases.add(invalid("a.{x;; y}"));
        cases.add(invalid("a.{x;;; y}"));
        cases.add(invalid("a.{x; ; y}"));

        return cases;
    }

    private static void collectTerminals(ParseTree tree, List<TerminalNode> terminals) {
        if (tree instanceof TerminalNode) {
            terminals.add((TerminalNode) tree);
            return;
        }
        for (int index = 0; index < tree.getChildCount(); index++) {
            collectTerminals(tree.getChild(index), terminals);
        }
    }

    private static void assertOperatorRules(TestCase testCase, ParseTree tree, SysMLv2Parser parser) {
        List<TerminalNode> terminals = new ArrayList<>();
        collectTerminals(tree, terminals);

        if (testCase.requiredRule != null && !containsRule(tree, testCase.requiredRule)) {
            throw new AssertionError(
                    "Expected `"
                            + testCase.input
                            + "` to contain "
                            + testCase.requiredRule
                            + "\n"
                            + tree.toStringTree(parser));
        }

        for (Map.Entry<String, String> expectation : testCase.operatorRules.entrySet()) {
            List<TerminalNode> matches = new ArrayList<>();
            for (TerminalNode terminal : terminals) {
                if (expectation.getKey().equals(terminal.getText())) {
                    matches.add(terminal);
                    String actualRule = terminal.getParent().getClass().getSimpleName();
                    if (!expectation.getValue().equals(actualRule)) {
                        throw new AssertionError(
                                "Unexpected rule for "
                                        + expectation.getKey()
                                        + " in `"
                                        + testCase.input
                                        + "`: expected "
                                        + expectation.getValue()
                                        + ", got "
                                        + actualRule
                                        + "\n"
                                        + tree.toStringTree(parser));
                    }
                }
            }
            if (matches.isEmpty()) {
                throw new AssertionError("Operator `" + expectation.getKey() + "` was not found in `" + testCase.input + "`");
            }
            Boolean requireSameParent = testCase.sameParent.get(expectation.getKey());
            if (requireSameParent != null && matches.size() != 2) {
                throw new AssertionError("Expected exactly two `" + expectation.getKey() + "` operators in `" + testCase.input + "`");
            }
            if (requireSameParent != null) {
                boolean actualSameParent = matches.get(0).getParent() == matches.get(1).getParent();
                if (actualSameParent != requireSameParent) {
                    throw new AssertionError("Unexpected associativity for `" + testCase.input + "`\n" + tree.toStringTree(parser));
                }
            }
        }

        if (testCase.outermostOperator != null) {
            TerminalNode outer = findTerminal(terminals, testCase.outermostOperator);
            ParseTree outerContext = outer.getParent();
            for (TerminalNode terminal : terminals) {
                if (terminal == outer || !testCase.operatorRules.containsKey(terminal.getText())) {
                    continue;
                }
                if (!isAncestor(outerContext, terminal.getParent())) {
                    throw new AssertionError(
                            "Expected `"
                                    + testCase.outermostOperator
                                    + "` to contain the other operators in `"
                                    + testCase.input
                                    + "`\n"
                                    + tree.toStringTree(parser));
                }
            }
        }
    }

    private static TerminalNode findTerminal(List<TerminalNode> terminals, String text) {
        for (TerminalNode terminal : terminals) {
            if (text.equals(terminal.getText())) {
                return terminal;
            }
        }
        throw new AssertionError("Operator `" + text + "` was not found in the parse tree");
    }

    private static boolean isAncestor(ParseTree ancestor, ParseTree node) {
        for (ParseTree current = node; current != null; current = current.getParent()) {
            if (current == ancestor) {
                return true;
            }
        }
        return false;
    }

    private static boolean containsRule(ParseTree tree, String rule) {
        if (tree.getClass().getSimpleName().equals(rule)) {
            return true;
        }
        for (int index = 0; index < tree.getChildCount(); index++) {
            if (containsRule(tree.getChild(index), rule)) {
                return true;
            }
        }
        return false;
    }

    private static void run(TestCase testCase) {
        ErrorCollector lexerErrors = new ErrorCollector();
        SysMLv2Lexer lexer = new SysMLv2Lexer(CharStreams.fromString(testCase.input));
        lexer.removeErrorListeners();
        lexer.addErrorListener(lexerErrors);

        CommonTokenStream tokens = new CommonTokenStream(lexer);
        ErrorCollector parserErrors = new ErrorCollector();
        SysMLv2Parser parser = new SysMLv2Parser(tokens);
        parser.removeErrorListeners();
        parser.addErrorListener(parserErrors);
        parser.getInterpreter().setPredictionMode(PredictionMode.LL_EXACT_AMBIG_DETECTION);
        ParseTree tree = parser.ownedExpression();
        boolean consumedEof = parser.getCurrentToken().getType() == Token.EOF;
        boolean actualValid =
                lexerErrors.messages.isEmpty()
                        && parserErrors.messages.isEmpty()
                        && parserErrors.ambiguities == 0
                        && consumedEof;

        if (actualValid != testCase.valid) {
            throw new AssertionError(
                    "Unexpected validity for `"
                            + testCase.input
                            + "`: expected "
                            + testCase.valid
                            + ", got "
                            + actualValid
                            + "\nlexer="
                            + lexerErrors.messages
                            + "\nparser="
                            + parserErrors.messages
                            + "\nambiguities="
                            + parserErrors.ambiguities
                            + "\n"
                            + tree.toStringTree(parser));
        }
        if (actualValid) {
            assertOperatorRules(testCase, tree, parser);
        }
        System.out.println((testCase.valid ? "PASS valid  " : "PASS invalid") + "  " + testCase.input);
    }

    private static void runRoot(String input, boolean valid) {
        ErrorCollector lexerErrors = new ErrorCollector();
        SysMLv2Lexer lexer = new SysMLv2Lexer(CharStreams.fromString(input));
        lexer.removeErrorListeners();
        lexer.addErrorListener(lexerErrors);

        CommonTokenStream tokens = new CommonTokenStream(lexer);
        ErrorCollector parserErrors = new ErrorCollector();
        SysMLv2Parser parser = new SysMLv2Parser(tokens);
        parser.removeErrorListeners();
        parser.addErrorListener(parserErrors);
        parser.getInterpreter().setPredictionMode(PredictionMode.LL_EXACT_AMBIG_DETECTION);
        ParseTree tree = parser.rootNamespace();
        boolean consumedEof = parser.getCurrentToken().getType() == Token.EOF;
        boolean actualValid =
                lexerErrors.messages.isEmpty()
                        && parserErrors.messages.isEmpty()
                        && parserErrors.ambiguities == 0
                        && consumedEof;

        if (actualValid != valid) {
            throw new AssertionError(
                    "Unexpected root validity for `"
                            + input
                            + "`: expected "
                            + valid
                            + ", got "
                            + actualValid
                            + "\nlexer="
                            + lexerErrors.messages
                            + "\nparser="
                            + parserErrors.messages
                            + "\nambiguities="
                            + parserErrors.ambiguities
                            + "\n"
                            + tree.toStringTree(parser));
        }
        System.out.println((valid ? "PASS root valid  " : "PASS root invalid") + "  " + input);
    }

    public static void main(String[] args) {
        int count = 0;
        for (TestCase testCase : cases()) {
            run(testCase);
            count++;
        }

        String[] rootValid = {
            "package P { attribute x = a.{ x }; }",
            "package P { attribute x = a.?{ in ref xx; xx + 1 }; }",
            "package P { attribute x = a->collect { in xx; xx + 1 }; }",
            "package P { attribute x = a.{ private attribute y := z; y }; }",
            "package P { attribute x = a.{ return x; x }; }",
            "package P { attribute x = a + b * c; }",
            "package P { attribute x = a.;; }",
            "package P { attribute x = a.?;; }",
            "package P { attribute x = a->F;; }",
        };
        for (String input : rootValid) {
            runRoot(input, true);
        }

        String[] rootInvalid = {
            "package P { attribute x = a[]; }",
            "package P { attribute x = a#(); }",
            "package P { attribute x = a istype T + b; }",
        };
        for (String input : rootInvalid) {
            runRoot(input, false);
        }

        System.out.println(
                "Expression grammar checks passed: "
                        + count
                        + " plus "
                        + rootValid.length
                        + " root-valid and "
                        + rootInvalid.length
                        + " root-invalid cases");
    }
}
