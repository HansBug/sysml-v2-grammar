import java.util.ArrayList;
import java.util.List;

import org.antlr.v4.runtime.BaseErrorListener;
import org.antlr.v4.runtime.CharStreams;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.Parser;
import org.antlr.v4.runtime.RecognitionException;
import org.antlr.v4.runtime.Recognizer;
import org.antlr.v4.runtime.Token;
import org.antlr.v4.runtime.atn.ATNConfigSet;
import org.antlr.v4.runtime.atn.PredictionMode;
import org.antlr.v4.runtime.dfa.DFA;
import org.antlr.v4.runtime.tree.ParseTree;
import org.antlr.v4.runtime.tree.TerminalNode;

/** Focused parser regressions for expression precedence and boundaries. */
public final class ExpressionGrammarTest {
    private static final class Errors extends BaseErrorListener {
        private int syntaxErrors;
        private int exactAmbiguities;

        @Override
        public void syntaxError(
                Recognizer<?, ?> recognizer,
                Object offendingSymbol,
                int line,
                int charPositionInLine,
                String message,
                RecognitionException exception) {
            syntaxErrors++;
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
            if (exact) {
                exactAmbiguities++;
            }
        }
    }

    private static final class Case {
        private final String input;
        private final boolean accepted;
        private String rootOperator;
        private String associativeOperator;
        private boolean leftAssociative;
        private String conditionOperator;
        private String thenOperator;
        private String elseOperator;
        private boolean checkConditional;

        private Case(String input, boolean accepted) {
            this.input = input;
            this.accepted = accepted;
        }

        private Case root(String operator) {
            rootOperator = operator;
            return this;
        }

        private Case left(String operator) {
            associativeOperator = operator;
            leftAssociative = true;
            return this;
        }

        private Case right(String operator) {
            associativeOperator = operator;
            leftAssociative = false;
            return this;
        }

        private Case branches(String condition, String thenBranch, String elseBranch) {
            checkConditional = true;
            conditionOperator = condition;
            thenOperator = thenBranch;
            elseOperator = elseBranch;
            return this;
        }
    }

    private static Case valid(String input) {
        return new Case(input, true);
    }

    private static Case invalid(String input) {
        return new Case(input, false);
    }

    private static List<Case> expressionCases() {
        List<Case> cases = new ArrayList<>();

        String[][] precedence = {
            {"a + b * c", "+"},
            {"a * b + c", "+"},
            {"a .. b + c", ".."},
            {"a + b .. c", ".."},
            {"a < b .. c", "<"},
            {"a .. b < c", "<"},
            {"a < b == c", "=="},
            {"a == b < c", "=="},
            {"a and b == c", "and"},
            {"a == b and c", "and"},
            {"a xor b and c", "xor"},
            {"a and b xor c", "xor"},
            {"a or b xor c", "or"},
            {"a xor b or c", "or"},
            {"a implies b or c", "implies"},
            {"a or b implies c", "implies"},
            {"a ?? b implies c", "??"},
            {"a implies b ?? c", "??"},
            {"a == b & c xor d | e implies f ?? g", "??"},
        };
        for (String[] pair : precedence) {
            cases.add(valid(pair[0]).root(pair[1]));
        }

        for (String operator : new String[] {
            "+", "-", "*", "/", "%", "..", "<", "==", "&", "and", "xor", "|", "or", "implies", "??"
        }) {
            cases.add(valid("a " + operator + " b " + operator + " c").left(operator));
        }
        cases.add(valid("a ** b ** c").right("**"));
        cases.add(valid("a ^ b ^ c").right("^"));
        cases.add(valid("a ** b ^ c").root("**"));
        cases.add(valid("a ^ b ** c").root("^"));

        cases.add(valid("if a ? b else c").root("if").branches(null, null, null));
        cases.add(valid("if a + b ? c * d else e ** f").root("if").branches("+", "*", "**"));
        cases.add(valid("if a ? b else c + d").root("if").branches(null, null, "+"));
        cases.add(valid("if a ? b else c ?? d").root("if").branches(null, null, "??"));
        cases.add(valid("if if a ? b else c ? d else e").root("if").branches("if", null, null));
        cases.add(valid("if a ? if b ? c else d else e").root("if").branches(null, "if", null));
        cases.add(valid("if a ? b else if c ? d else e").root("if").branches(null, null, "if"));
        cases.add(valid("a + if b ? c else d").root("+").branches(null, null, null));
        cases.add(valid("a + if b ? c else d + e").root("+").branches(null, null, "+"));
        cases.add(valid("a + if b ? c else d ?? e").root("+").branches(null, null, "??"));
        cases.add(valid("a ** if b ? c else d").root("**").branches(null, null, null));
        cases.add(valid("-if b ? c else d").root("-"));
        cases.add(valid("not if b ? c else d").root("not"));

        for (String input : new String[] {
            "istype T", "hastype T", "@ T", "as T", "a istype T", "a @@ T", "a meta T",
            "a istype T + b", "a + b istype T", "a as T + b", "a + b as T", "a == b istype T",
            "a + b @@ T", "a @@ T + b", "a meta T < b", "a @@ T as U", "a @@ T == b", "a meta T == b",
            "a istype T as U", "(as T).isMandatory",
        }) {
            cases.add(valid(input));
        }
        for (String input : new String[] {"@@ T", "meta T", "a.metadata @@ T", "a istype", "a @@"}) {
            cases.add(invalid(input));
        }

        for (String input : new String[] {
            "a.b", "a.b.c", "a()", "a.f()", "a().b", "a.f().g", "a.f.g()", "a + b.f", "a + b[1]",
            "a[1].b", "a[1,]", "a#(1).b", "a.f()[1]",
            "a.b[1,].d", "(a,)", "()", "a(x = b)", "new T()", "new A.B()", "a->F()", "a->F {}", "a.{}", "a.?{}",
        }) {
            cases.add(valid(input));
        }

        for (String input : new String[] {
            "a ? b else c", "if a ? b", "if a ? b else", "if a b ? c else d", "a +", "a **", "-", "not",
            "a[]", "a#()", "a(b)(c)", "a()()", "a.f()()", "a.f().g()", "a.f(x).g(y)", "a->F().g()",
            "a[1].f()", "a#(1).f()", "a.{}.f()", "(a + b).f()", "a->F", "a->F.g", "a + b c", "a + ?", "a + b trailing",
        }) {
            cases.add(invalid(input));
        }
        return cases;
    }

    private static List<TerminalNode> terminals(ParseTree tree, String text) {
        List<TerminalNode> result = new ArrayList<>();
        if (tree instanceof TerminalNode) {
            if (text.equals(tree.getText())) {
                result.add((TerminalNode) tree);
            }
            return result;
        }
        for (int index = 0; index < tree.getChildCount(); index++) {
            result.addAll(terminals(tree.getChild(index), text));
        }
        return result;
    }

    private static boolean hasDirectTerminal(ParseTree tree, String text) {
        for (int index = 0; index < tree.getChildCount(); index++) {
            ParseTree child = tree.getChild(index);
            if (child instanceof TerminalNode && text.equals(child.getText())) {
                return true;
            }
        }
        return false;
    }

    private static ParseTree findConditional(ParseTree tree) {
        if (hasDirectTerminal(tree, "if")) {
            return tree;
        }
        for (int index = 0; index < tree.getChildCount(); index++) {
            ParseTree found = findConditional(tree.getChild(index));
            if (found != null) {
                return found;
            }
        }
        return null;
    }

    private static List<ParseTree> conditionalBranches(ParseTree tree) {
        List<ParseTree> branches = new ArrayList<>();
        for (int index = 0; index < tree.getChildCount(); index++) {
            ParseTree child = tree.getChild(index);
            if (!(child instanceof TerminalNode)) {
                branches.add(child);
            }
        }
        return branches;
    }

    private static void checkBranch(ParseTree branch, String expected, String input) {
        if (expected != null && !hasDirectTerminal(branch, expected)) {
            throw new AssertionError(
                    "Unexpected conditional branch for `" + input + "`: expected `" + expected + "`\n"
                            + branch.toStringTree());
        }
    }

    private static void checkShape(Case testCase, ParseTree tree) {
        if (testCase.rootOperator != null) {
            List<TerminalNode> roots = terminals(tree, testCase.rootOperator);
            boolean rootFound = false;
            for (TerminalNode terminal : roots) {
                if (terminal.getParent() == tree) {
                    rootFound = true;
                    break;
                }
            }
            if (!rootFound) {
                throw new AssertionError("Unexpected root for `" + testCase.input + "`: " + tree.toStringTree());
            }
        }
        if (testCase.associativeOperator != null) {
            List<TerminalNode> operators = terminals(tree, testCase.associativeOperator);
            if (operators.size() != 2) {
                throw new AssertionError("Expected two operators in `" + testCase.input + "`");
            }
            boolean firstIsRoot = operators.get(0).getParent() == tree;
            if (firstIsRoot == testCase.leftAssociative) {
                throw new AssertionError("Unexpected associativity for `" + testCase.input + "`: " + tree.toStringTree());
            }
        }

        if (testCase.checkConditional) {
            ParseTree conditional = findConditional(tree);
            if (conditional == null) {
                throw new AssertionError("Expected conditional expression for `" + testCase.input + "`");
            }
            List<ParseTree> branches = conditionalBranches(conditional);
            if (branches.size() != 3) {
                throw new AssertionError("Conditional does not have three branches for `" + testCase.input + "`");
            }
            checkBranch(branches.get(0), testCase.conditionOperator, testCase.input);
            checkBranch(branches.get(1), testCase.thenOperator, testCase.input);
            checkBranch(branches.get(2), testCase.elseOperator, testCase.input);
        }
    }

    private static final class ParseResult {
        private final ParseTree tree;
        private final Errors lexerErrors;
        private final Errors parserErrors;
        private final boolean eof;

        private ParseResult(ParseTree tree, Errors lexerErrors, Errors parserErrors, boolean eof) {
            this.tree = tree;
            this.lexerErrors = lexerErrors;
            this.parserErrors = parserErrors;
            this.eof = eof;
        }

        private boolean accepted() {
            return lexerErrors.syntaxErrors == 0
                    && parserErrors.syntaxErrors == 0
                    && parserErrors.exactAmbiguities == 0
                    && eof;
        }

        private String diagnostics() {
            return "lexerErrors=" + lexerErrors.syntaxErrors
                    + ", parserErrors=" + parserErrors.syntaxErrors
                    + ", exactAmbiguities=" + parserErrors.exactAmbiguities
                    + ", eof=" + eof;
        }
    }

    private static ParseResult parse(String input, boolean root) {
        Errors lexerErrors = new Errors();
        SysMLv2Lexer lexer = new SysMLv2Lexer(CharStreams.fromString(input));
        lexer.removeErrorListeners();
        lexer.addErrorListener(lexerErrors);
        CommonTokenStream tokens = new CommonTokenStream(lexer);
        tokens.fill();
        Errors parserErrors = new Errors();
        SysMLv2Parser parser = new SysMLv2Parser(tokens);
        parser.removeErrorListeners();
        parser.addErrorListener(parserErrors);
        parser.getInterpreter().setPredictionMode(PredictionMode.LL_EXACT_AMBIG_DETECTION);
        ParseTree tree = root ? parser.rootNamespace() : parser.ownedExpression();
        return new ParseResult(
                tree,
                lexerErrors,
                parserErrors,
                parser.getCurrentToken().getType() == Token.EOF);
    }

    public static void main(String[] args) {
        List<Case> cases = expressionCases();
        int accepted = 0;
        int rejected = 0;
        for (int index = 0; index < cases.size(); index++) {
            Case testCase = cases.get(index);
            ParseResult result = parse(testCase.input, false);
            boolean actual = result.accepted();
            if (actual != testCase.accepted) {
                throw new AssertionError(
                        "Case " + (index + 1) + " expected " + testCase.accepted + " for `" + testCase.input
                                + "`: " + result.diagnostics() + "\n" + result.tree.toStringTree());
            }
            if (actual) {
                checkShape(testCase, result.tree);
            }
            if (actual) {
                accepted++;
            } else {
                rejected++;
            }
        }

        String[] validRoots = {
            "package P { attribute x = a + b; }",
            "package P { attribute x = if a ? b else c + d; }",
        };
        for (String input : validRoots) {
            ParseResult result = parse(input, true);
            if (!result.accepted()) {
                throw new AssertionError("Root expression should be accepted: " + input + ": " + result.diagnostics());
            }
        }
        String invalidRoot = "package P { attribute x = a + ; }";
        ParseResult invalidResult = parse(invalidRoot, true);
        if (invalidResult.accepted()) {
            throw new AssertionError("Root expression should be rejected: " + invalidRoot);
        }

        System.out.println(
                "Expression grammar checks passed: " + cases.size()
                        + " cases (" + accepted + " accepted, " + rejected + " rejected); root entrypoint passed");
    }
}
