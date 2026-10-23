#!/opt/local/amster_python_env/bin/python
# -----------------------------------------------------------------------------------------
# This script searches the dependencies of one shell or Python script, or of all the
# scripts in the current directory and its sub-directories (.git and __pycache__ are
# skipped), and lists them in the terminal.
#
# For each script, the dependencies are listed as a tree:
#   - [script ] shell or Python scripts it calls, with their own dependencies (recursively)
#   - [module ] Python modules it imports (local, stdlib, installed or MISSING)
#   - [command] external commands it runs (resolved with the PATH of the current session)
#   - [call   ] eval, whose code is only known at run time
#
# Each item is followed by the line numbers where it was found, to allow checking.
# The end of the listing shows everything that must be checked by hand: missing
# scripts or modules, unknown commands and dynamic calls. Comment lines are ignored, as
# well as what is only displayed (arguments of echo or printf, of print() in Python).
#
# Commands and scripts outside the tree are resolved with the PATH of the session, and
# Python modules with the Python running this script: run it in the AMSTer environment.
#
# Commands found in /bin or /usr/bin (standard system commands), $HOME/SAR/AMSTer/AMSTerEngine 
# and $HOME/SAR/AMSTer/MSBAS (and their sub-directories) are not listed.
#
# Commands given by a variable (${SED}, "$CMD", subprocess.run(cmd)...) are not listed.
#
# MISSING 		means “it should exist but doesn’t”, 
# UNRESOLVED 	means “looks like a program but isn’t in the PATH”, and 
# DYNAMIC 		means “can’t be known without running the script”.
#
# Parameters are:
#       - optional: path to a script: list only the dependencies of that script (and of
#                   its dependencies). Without it, all the scripts of the current
#                   directory and its sub-directories are listed. In both cases the
#                   current directory is scanned to resolve the names of the scripts.
#       - optional: -v  verbose: also list the commands and the dynamic calls in the
#                       trees (by default only scripts and Python modules are listed);
#                       the final summary is always complete.
#
#   e.g.  cd $HOME/SAR/AMSTer/SCRIPTS_MT ; Search_Dependencies.py __SplitCoreg.sh -v
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies: - Python 3.8 or later (AMSTer venv)
#
# New in Distro V 1.1 20261012: - avoid ".sh and do script
# New in Distro V 2.0 20261012: - rewritten in Python. Shell scripts are read with a small
#                                 parser that understands comments, quotes, command
#                                 substitutions and heredocs; Python scripts are parsed with ast.
#                               - detects external commands (not only .sh and .py), resolves
#                                 every dependency and lists the dependencies of the
#                                 dependencies recursively.
#                               - summary of what could not be resolved.
# New in Distro V 2.1 20261013:	- Recommend using Search_Dependencies.py for 
#								  an updated list of dependencies
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - 
# -----------------------------------------------------------------------------------------

import argparse
import ast
import functools
import importlib.util
import os
import re
import shutil
import sys
import sysconfig
from dataclasses import dataclass, field

PRG = os.path.basename(sys.argv[0])
VER = "Distro V2.0 AMSTer script utilities"
AUT = "Nicolas d'Oreye, (c)2016-2026, Last modified on Oct 12, 2026"

SKIPPED_DIRS = {".git", "__pycache__"}
# Standard system commands (ls, grep, rm...) found in these directories are not listed
SYSTEM_COMMAND_DIRS = {"/bin", "/usr/bin"}
SHELL_EXTENSIONS = {".sh", ".bash", ".ksh", ".zsh"}
QUOTED = "__QUOTED__"           # replaces quoted strings in the "command view" of shell code
QUOTED_RE = re.compile(QUOTED + r"(\d+)__")     # __QUOTED__3__ : the 4th quoted string
DISPLAY_COMMANDS = {"echo", "printf"}           # their arguments are displayed, not run
PROBLEMS = {"MISSING", "UNRESOLVED", "DYNAMIC"}

# A script name written anywhere: foo.sh, ./foo.sh, ${PATH_SCRIPTS}/foo.py, "foo.sh", ...
# (not *.sh, which is a pattern, nor foo.sh.bak)
SCRIPT_NAME_RE = re.compile(r"(?<![\w.+*-])([\w+-][\w.+-]*\.(?:sh|py))(?![\w-]|\.\w)")

SHELL_KEYWORDS = {"if", "then", "else", "elif", "fi", "case", "esac", "for", "select", "while",
                  "until", "do", "done", "in", "function", "time", "{", "}", "[[", "]]", "!",
                  "coproc"}
SHELL_BUILTINS = {"alias", "bg", "bind", "break", "builtin", "caller", "cd", "command",
                  "compgen", "complete", "compopt", "continue", "declare", "dirs", "disown",
                  "echo", "enable", "eval", "exec", "exit", "export", "false", "fc", "fg",
                  "getopts", "hash", "help", "history", "jobs", "kill", "let", "local",
                  "logout", "mapfile", "popd", "printf", "pushd", "pwd", "read", "readarray",
                  "readonly", "return", "set", "shift", "shopt", "source", ".", "suspend",
                  "test", "times", "trap", "true", "type", "typeset", "ulimit", "umask",
                  "unalias", "unset", "wait", "[", ":"}
# Words after which the next word is again a command: "then cmd", "nohup cmd", "xargs -n 1 cmd"
COMMAND_PREFIXES = {"then", "do", "else", "elif", "if", "while", "until", "!", "time", "{", "}",
                    "exec", "command", "builtin", "nohup", "sudo", "env", "nice", "timeout",
                    "xargs"}

SEPARATOR_RE = re.compile(r"[;&|()`]")
CASE_LABEL_RE = re.compile(r"^\s*\(?[^\s()$=;]+\)(?=\s|$)")     # Linux)   [Yy]*)
REDIRECTION_RE = re.compile(r"^\d*(>>?|<<?<?)")
ASSIGNMENT_RE = re.compile(r"^[A-Za-z_]\w*(\[[^\]]*\])?\+?=")
COMMAND_NAME_RE = re.compile(r"^[\w.+-]+$")
HEREDOC_RE = re.compile(r"(?<!<)<<-?\s*(['\"]?)([A-Za-z_][\w.-]*)\1")
FUNCTION_DEF_RE = re.compile(r"^\s*(?:function\s+([\w.:-]+)|([\w.:-]+)\s*\(\s*\))", re.M)

SUBPROCESS_FUNCTIONS = {"run", "call", "Popen", "check_call", "check_output", "getoutput",
                        "getstatusoutput", "system", "popen"}
STDLIB_MODULES = set(getattr(sys, "stdlib_module_names", ())) | set(sys.builtin_module_names)
STDLIB_DIR = sysconfig.get_paths()["stdlib"]

which = functools.lru_cache(maxsize=None)(shutil.which)

# Directories where AMSTer keeps its own executables (engine, MSBAS). Commands found there
# are resolved even when these directories are not in the PATH of the session.
AMSTER_DIRS = [os.path.expanduser("~/SAR/AMSTer/AMSTerEngine"),
               os.path.expanduser("~/SAR/AMSTer/MSBAS")]


@functools.lru_cache(maxsize=None)
def amster_executables():
    """Executable files of AMSTER_DIRS and their sub-directories: name -> path (first found)."""
    found = {}
    for top in AMSTER_DIRS:
        for directory, subdirs, files in os.walk(top):      # nothing if top does not exist
            subdirs[:] = sorted(d for d in subdirs if d not in SKIPPED_DIRS)
            for name in sorted(files):
                path = os.path.join(directory, name)
                if name not in found and os.path.isfile(path) and os.access(path, os.X_OK):
                    found[name] = path
    return found
# ----------------------------------------------------------------------------------------
# Data
# ----------------------------------------------------------------------------------------
@dataclass
class Dep:
    kind: str       # script, module, command, call
    name: str
    status: str     # tree, PATH, local, stdlib, installed, MISSING, UNRESOLVED, DYNAMIC
    path: str = ""
    note: str = ""
    lines: set = field(default_factory=set)


class Deps:
    """Direct dependencies of one script, merged by (kind, name)."""
    ORDER = {"script": 0, "module": 1, "command": 2, "call": 3}

    def __init__(self):
        self.items = {}

    def add(self, kind, name, status, line, path="", note=""):
        key = (kind, name)
        if key not in self.items:
            self.items[key] = Dep(kind, name, status, path, note)
        self.items[key].lines.add(line)

    def sorted(self):
        return sorted(self.items.values(), key=lambda d: (self.ORDER[d.kind], d.name))


class Context:
    """Scripts of the tree, indexes to resolve names, and results of the analyses."""

    def __init__(self, root):
        self.root = root
        self.scripts = []        # all shell and Python scripts of the tree
        self.by_name = {}        # file name   -> [paths]   (scripts of the tree)
        self.py_modules = {}     # module name -> [paths]   (.py files and packages of the tree)
        self.cache = {}          # path -> sorted list of Dep
        self.warnings = {}       # path -> [messages]
        for directory, subdirs, files in os.walk(root):
            subdirs[:] = sorted(d for d in subdirs if d not in SKIPPED_DIRS)
            if "__init__.py" in files:
                package = os.path.basename(directory)
                self.py_modules.setdefault(package, []).append(os.path.join(directory, "__init__.py"))
            for name in sorted(files):
                path = os.path.join(directory, name)
                if os.path.isfile(path) and script_language(path):
                    self.scripts.append(path)
                    self.by_name.setdefault(name, []).append(path)
                    if name.endswith(".py"):
                        self.py_modules.setdefault(name[:-3], []).append(path)
        self.scripts.sort()

    def warn(self, path, message):
        self.warnings.setdefault(path, []).append(message)

    def show(self, path):
        """Path relative to the scanned directory when inside it, absolute otherwise."""
        if path.startswith(self.root + os.sep):
            return "." + path[len(self.root):]
        return path


# ----------------------------------------------------------------------------------------
# Files
# ----------------------------------------------------------------------------------------
def script_language(path):
    """'shell', 'python', or None when the file is not a script (data, binary...)."""
    extension = os.path.splitext(path)[1].lower()
    if extension in SHELL_EXTENSIONS:
        return "shell"
    if extension == ".py":
        return "python"
    try:
        with open(path, "rb") as f:
            first_line = f.readline(256)
    except OSError:
        return None
    if not first_line.startswith(b"#!"):
        return None
    if b"python" in first_line:
        return "python"
    if re.search(rb"\b(ba|z|k|da)?sh\b", first_line):
        return "shell"
    return None


def read_text(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        return f.read()


# ----------------------------------------------------------------------------------------
# Resolution of names
# ----------------------------------------------------------------------------------------
def add_script(deps, ctx, name, line, from_dir):
    """A script referenced by its name: look in the tree first, then in the PATH."""
    candidates = ctx.by_name.get(name, [])
    if candidates:
        same_dir = [p for p in candidates if os.path.dirname(p) == from_dir]
        note = f"{len(candidates)} files with this name in the tree" if len(candidates) > 1 else ""
        deps.add("script", name, "tree", line, (same_dir or candidates)[0], note)
    elif which(name):
        deps.add("script", name, "PATH", line, which(name))
    else:
        deps.add("script", name, "MISSING", line)


def add_command(deps, ctx, word, line, from_dir, functions=()):
    """A word in command position (shell code, or a command run from Python)."""
    name = word.rsplit("/", 1)[-1]                # ${PATHGNU}/grep -> grep
    if word == "$" or not name:
        return                                    # start of $( ... ): its content is analysed
    if "$" in name or QUOTED in name:
        return                                    # command in a variable: ${SED}, "$CMD", ${PREFIX}tool
    if name == "eval":
        deps.add("call", "eval", "DYNAMIC", line)
        return
    if name.startswith("-") or name.isdigit() or not COMMAND_NAME_RE.match(name):
        return
    if name in SHELL_BUILTINS or name in SHELL_KEYWORDS or name in functions:
        return
    if SCRIPT_NAME_RE.fullmatch(name) or name in ctx.by_name:
        add_script(deps, ctx, name, line, from_dir)
    elif which(name):
        if os.path.dirname(which(name)) not in SYSTEM_COMMAND_DIRS:
            deps.add("command", name, "PATH", line, which(name))
    elif name in amster_executables():
        deps.add("command", name, "AMSTer", line, amster_executables()[name])
    else:
        deps.add("command", name, "UNRESOLVED", line)
        
@functools.lru_cache(maxsize=None)
def find_module(name):
    try:
        spec = importlib.util.find_spec(name)
    except (ImportError, ValueError):
        return None
    if spec is None:
        return None
    if spec.origin and spec.origin not in ("built-in", "frozen", "namespace"):
        return spec.origin
    locations = list(spec.submodule_search_locations or [])
    return locations[0] if locations else spec.origin or "built-in"


def add_module(deps, ctx, name, line, from_dir):
    """Classify an imported module in the order Python itself would find it."""
    local = ctx.py_modules.get(name, [])
    same_dir = [p for p in local if os.path.dirname(p) == from_dir
                or os.path.dirname(os.path.dirname(p)) == from_dir]
    if same_dir:
        deps.add("module", name, "local", line, same_dir[0])
        return
    if name in STDLIB_MODULES:
        deps.add("module", name, "stdlib", line)
        return
    origin = find_module(name)
    if origin:
        if origin in ("built-in", "frozen") or (origin.startswith(STDLIB_DIR) and "-packages" not in origin):
            deps.add("module", name, "stdlib", line)
        elif origin.startswith(ctx.root + os.sep):
            deps.add("module", name, "local", line, origin)
        else:
            deps.add("module", name, "installed", line, origin)
    elif local:
        deps.add("module", name, "local", line, local[0],
                 "in the tree, but neither next to the script nor in sys.path: check PYTHONPATH")
    else:
        deps.add("module", name, "MISSING", line)


# ----------------------------------------------------------------------------------------
# Shell scripts
# ----------------------------------------------------------------------------------------
def split_heredocs(text):
    """Return (text with heredoc bodies replaced by empty lines, [(line, body line)]).
    Bodies are data (messages, input of other programs) that may contain unbalanced
    quotes, so they must not reach the shell parser. Line numbers are kept."""
    lines = text.split("\n")
    out, bodies, i = [], [], 0
    while i < len(lines):
        out.append(lines[i])
        match = HEREDOC_RE.search(lines[i])
        if match and not lines[i].lstrip().startswith("#"):
            delimiter = match.group(2)
            end = next((j for j in range(i + 1, len(lines)) if lines[j].strip() == delimiter), None)
            if end is not None:        # no terminator: "<<" was not a heredoc, keep the lines
                bodies.extend((j + 1, lines[j]) for j in range(i + 1, end))
                out.extend([""] * (end - i))
                i = end
        i += 1
    return "\n".join(out), bodies


def scan_shell(text):
    """Return two views of shell code, with the same line numbers as the original:
        code : the text without its comments (quoted strings kept)
        view : the code where every quoted string is replaced by the word __QUOTED__n__, except
               the command substitutions $( ) and ` ` they contain; arithmetic is removed.
    A small state machine is used because quotes, comments and command substitutions
    can be nested, which regular expressions cannot follow.
        strings : the content of the quoted strings; strings[n] is the one of __QUOTED__n__"""
    code, view, strings = [], [], []
    stack = [["code", 0]]       # [state, parenthesis depth]; states: code sub bt dq arith
    hidden_newlines = 0         # newlines inside strings, re-emitted at the next code newline
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        nxt = text[i + 1] if i + 1 < n else ""
        state = stack[-1][0]
        in_code = state in ("code", "sub", "bt")

        if c == "\\":                                   # escaped character
            code.append(c + nxt)
            if nxt == "\n":
                hidden_newlines += 1
            if in_code:
                view.append(nxt if (nxt.isalnum() or nxt == "_") else " ")
            i += 2
            continue

        if state == "arith":                            # $(( ... )) or (( ... ))
            code.append(c)
            if c == "(":
                stack[-1][1] += 1
            elif c == ")":
                stack[-1][1] -= 1
                if stack[-1][1] == 0:
                    stack.pop()
            elif c == "\n":
                hidden_newlines += 1
            i += 1
            continue

        if state == "dq":                               # inside "..."
            if c == '"':
                _, _, index, start = stack.pop()
                strings[index] = text[start:i]
                code.append(c)
                i += 1
                continue
            if not ((c == "$" and nxt == "(") or c == "`"):
                code.append(c)
                if c == "\n":
                    hidden_newlines += 1
                i += 1
                continue
            # else: command substitution inside the string, handled below as code

        if text.startswith("$((", i) or (in_code and text.startswith("((", i)):
            size = 3 if c == "$" else 2
            code.append(text[i:i + size])
            if in_code:
                view.append("0")                        # x=$((a+1)) -> x=0
            stack.append(["arith", 2])
            i += size
            continue
        if c == "$" and nxt == "(":
            stack.append(["sub", 0])
            code.append("$(")
            view.append("$(")
            i += 2
            continue
        if c == "`":
            if state == "bt":
                stack.pop()
            else:
                stack.append(["bt", 0])
            code.append(c)
            view.append(c)
            i += 1
            continue
        # From here on, the state is code, sub or bt
        if c == "#" and (i == 0 or text[i - 1] in " \t\n;&|("):    # comment (not $# or ${#x})
            end = text.find("\n", i)
            i = n if end < 0 else end
            continue
        if c == "'":                                    # '...' : no escape, no expansion
            end = text.find("'", i + 1)
            end = n - 1 if end < 0 else end
            code.append(text[i:end + 1])
            strings.append(text[i + 1:end])
            view.append(f"{QUOTED}{len(strings) - 1}__")
            hidden_newlines += text.count("\n", i, end + 1)
            i = end + 1
            continue
        if c == '"':
            strings.append("")                         # filled when the string closes
            stack.append(["dq", 0, len(strings) - 1, i + 1])
            code.append(c)
            view.append(f"{QUOTED}{len(strings) - 1}__")
            i += 1
            continue
        if state == "sub" and c == "(":
            stack[-1][1] += 1
        elif state == "sub" and c == ")":
            if stack[-1][1] == 0:
                stack.pop()
            else:
                stack[-1][1] -= 1
        code.append(c)
        if c == "\n":
            view.append("\n" * (1 + hidden_newlines))
            hidden_newlines = 0
        else:
            view.append(c)
        i += 1
    return "".join(code), "".join(view), strings


def simple_commands(view):
    """Yield (line number, words) for every simple command of a command view."""
    for lineno, line in enumerate(view.split("\n"), 1):
        line = CASE_LABEL_RE.sub(" ", line)
        line = line.replace("&>", ">")                  # &>file
        line = re.sub(r"\d*[<>]&\d*-?", " ", line)      # 2>&1, >&2
        for segment in SEPARATOR_RE.split(line):
            yield lineno, segment.split()


def commands_in(words):
    """Yield the words in command position of one simple command."""
    skip_next = False
    for word in words:
        if skip_next:
            skip_next = False
            continue
        if REDIRECTION_RE.match(word):                  # "> file": the file is not a command
            skip_next = REDIRECTION_RE.fullmatch(word) is not None
            continue
        if ASSIGNMENT_RE.match(word) or word.startswith("-") or word.isdigit() or word == "{}":
            continue                                    # VAR=value, options of xargs, nice...
        if word in SHELL_KEYWORDS and word in COMMAND_PREFIXES:
            continue                                    # then, do, !, time...
        if word in SHELL_KEYWORDS:
            break                                       # for, case, [[ ... : not a command
        yield word
        if word.rsplit("/", 1)[-1] not in COMMAND_PREFIXES:
            break


def command_words(view):
    """Yield (line number, word) for every word in command position of a command view."""
    for lineno, words in simple_commands(view):
        for word in commands_in(words):
            yield lineno, word

SOURCE_RE = re.compile(r"(?:^|[;&|(]|\bthen|\bdo|\belse)\s*(?:source|\.)\s+(\S+)", re.M)


@functools.lru_cache(maxsize=None)
def shell_code(path):
    """Code of a shell file without comments and heredoc bodies (read once)."""
    text, _ = split_heredocs(read_text(path))
    code, _, _ = scan_shell(text)
    return code


def sourced_files(code, ctx, from_dir):
    """Paths of the shell files read with 'source file' or '. file' in this code."""
    paths = []
    for argument in SOURCE_RE.findall(code):
        for name in SCRIPT_NAME_RE.findall(argument):
            candidates = ctx.by_name.get(name, [])
            same_dir = [p for p in candidates if os.path.dirname(p) == from_dir]
            path = (same_dir or candidates or [which(name) or ""])[0]
            if path:
                paths.append(path)
    return paths


def defined_functions(path, ctx, visited):
    """Functions defined in a shell file and in the files it sources (recursively)."""
    if path in visited or script_language(path) != "shell":
        return set()
    visited.add(path)
    code = shell_code(path)
    functions = {a or b for a, b in FUNCTION_DEF_RE.findall(code)}
    for sourced in sourced_files(code, ctx, os.path.dirname(path)):
        functions |= defined_functions(sourced, ctx, visited)
    return functions

def analyse_shell(path, text, ctx, deps):
    from_dir = os.path.dirname(path)
    text, heredoc_lines = split_heredocs(text)
    code, view, strings = scan_shell(text)
    #functions = {a or b for a, b in FUNCTION_DEF_RE.findall(code)}
    # Functions of this file and of the files it sources (e.g. FUNCTIONS_FOR_MT.sh)
    functions = {a or b for a, b in FUNCTION_DEF_RE.findall(code)}
    for sourced in sourced_files(code, ctx, from_dir):
        functions |= defined_functions(sourced, ctx, {path})
    # 1. Scripts named in the code (calls, paths, arguments...), quoted or not, except in
    #    the arguments of echo and printf, which are only displayed. A command substitution
    #    inside these arguments, e.g. echo "$(foo.sh)", is a separate command: it is kept.
    for lineno, words in simple_commands(view):
        if any(word.rsplit("/", 1)[-1] in DISPLAY_COMMANDS for word in commands_in(words)):
            continue
        command_text = QUOTED_RE.sub(lambda m: strings[int(m.group(1))], " ".join(words))
        for name in SCRIPT_NAME_RE.findall(command_text):
            add_script(deps, ctx, name, lineno, from_dir)
    for lineno, line in heredoc_lines:                  # input given to other programs
        for name in SCRIPT_NAME_RE.findall(line):
            add_script(deps, ctx, name, lineno, from_dir)
    # 2. Words in command position (external commands, extension-less scripts)
    for lineno, word in command_words(view):
        add_command(deps, ctx, word, lineno, from_dir, functions)


# ----------------------------------------------------------------------------------------
# Python scripts
# ----------------------------------------------------------------------------------------
def literal_text(node):
    """Text of a string expression; parts only known at run time become ${VAR}."""
    if isinstance(node, ast.Constant) and isinstance(node.value, str):
        return node.value
    if isinstance(node, ast.JoinedStr):
        return "".join(v.value if isinstance(v, ast.Constant) else "${VAR}" for v in node.values)
    if isinstance(node, ast.BinOp) and isinstance(node.op, ast.Add):
        return (literal_text(node.left) or "${VAR}") + (literal_text(node.right) or "${VAR}")
    return None


def process_function(func, aliases):
    """Name of the function when the call is subprocess.run, os.system, os.exec*... else None."""
    if isinstance(func, ast.Attribute) and isinstance(func.value, ast.Name) and func.value.id in aliases:
        name = func.attr
    elif isinstance(func, ast.Name) and func.id in aliases:
        name = func.id
    else:
        return None
    if name in SUBPROCESS_FUNCTIONS or name.startswith(("exec", "spawn")):
        return name
    return None


def program_text(call, function):
    """Command text of a subprocess call (first argument, or first item of the list)."""
    index = 1 if function.startswith("spawn") else 0    # os.spawnv(mode, path, args)
    if len(call.args) > index:
        arg = call.args[index]
    else:
        arg = next((k.value for k in call.keywords if k.arg == "args"), None)
    if isinstance(arg, (ast.List, ast.Tuple)):
        arg = arg.elts[0] if arg.elts else None
    return literal_text(arg)


def add_shell_command_text(deps, ctx, text, line, from_dir):
    """Commands of a shell command line given as a string (Python subprocess call)."""
    _, view, _ = scan_shell(text)
    for _, word in command_words(view):
        add_command(deps, ctx, word, line, from_dir)


def add_relative_import(deps, path, node):
    base = os.path.dirname(path)
    for _ in range(node.level - 1):
        base = os.path.dirname(base)
    parts = [node.module] if node.module else [alias.name for alias in node.names]
    for part in parts:
        target = os.path.join(base, *part.split("."))
        found = next((p for p in (target + ".py", os.path.join(target, "__init__.py"))
                      if os.path.isfile(p)), None)
        if not found and node.module is None and os.path.isfile(os.path.join(base, "__init__.py")):
            found = os.path.join(base, "__init__.py")   # from . import name_defined_in_init
        deps.add("module", "." * node.level + part, "local" if found else "MISSING",
                 node.lineno, found or "")


def analyse_python(path, text, ctx, deps):
    from_dir = os.path.dirname(path)
    try:
        tree = ast.parse(text)
    except (SyntaxError, ValueError) as err:
        ctx.warn(path, f"not parsable by {sys.executable} ({type(err).__name__}, line "
                       f"{getattr(err, 'lineno', '?')}): searched with regular expressions only")
        analyse_python_with_regex(path, text, ctx, deps)
        return
    aliases = set()     # names under which os, subprocess or their functions are known
    # Strings only displayed by print() are not dependencies
    displayed = {id(part) for node in ast.walk(tree)
                 if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.func.id == "print"
                 for part in ast.walk(node)}
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                add_module(deps, ctx, alias.name.split(".")[0], node.lineno, from_dir)
                if alias.name in ("os", "subprocess"):
                    aliases.add(alias.asname or alias.name)
        elif isinstance(node, ast.ImportFrom):
            if node.level:
                add_relative_import(deps, path, node)
            else:
                add_module(deps, ctx, node.module.split(".")[0], node.lineno, from_dir)
                if node.module in ("os", "subprocess"):
                    aliases.update(alias.asname or alias.name for alias in node.names)
        elif isinstance(node, ast.Constant) and isinstance(node.value, str) and id(node) not in displayed:
            for name in SCRIPT_NAME_RE.findall(node.value):
                add_script(deps, ctx, name, node.lineno, from_dir)
    # Second pass: the aliases are only complete once all the imports were seen
    for node in ast.walk(tree):
        if isinstance(node, ast.Call):
            function = process_function(node.func, aliases)
            if function:
                command = program_text(node, function)
                if command is not None:              # None: command in a variable, not listed
                    add_shell_command_text(deps, ctx, command, node.lineno, from_dir)


PY_CALL_RE = re.compile(r"\b(?:system|popen|call|run|Popen|check_output|check_call)\(\s*\[?\s*[rbuf]?(['\"])(.*?)\1")


def analyse_python_with_regex(path, text, ctx, deps):
    """Fallback for files that the AMSTer Python cannot parse (e.g. Python 2 syntax)."""
    from_dir = os.path.dirname(path)
    for lineno, line in enumerate(text.split("\n"), 1):
        line = re.sub(r"(^|\s)#.*", "", line)
        words = line.split()
        if words[:1] == ["import"]:
            for module in line.split("import", 1)[1].split(","):
                if module.split():
                    add_module(deps, ctx, module.split()[0].split(".")[0], lineno, from_dir)
        elif words[:1] == ["from"] and "import" in words and len(words) > 1:
            if words[1].startswith("."):
                deps.add("module", words[1], "local", lineno, "", "relative import, not checked")
            else:
                add_module(deps, ctx, words[1].split(".")[0], lineno, from_dir)
        if not re.match(r"\s*print\b", line):          # print "..." only displays
            for name in SCRIPT_NAME_RE.findall(line):
                add_script(deps, ctx, name, lineno, from_dir)
        for _, command in PY_CALL_RE.findall(line):
            add_shell_command_text(deps, ctx, command, lineno, from_dir)


# ----------------------------------------------------------------------------------------
# Analysis and output
# ----------------------------------------------------------------------------------------
def analyse(path, ctx):
    """Sorted direct dependencies of one script (each script is analysed only once)."""
    if path not in ctx.cache:
        text = read_text(path)
        deps = Deps()
        if script_language(path) == "python":
            analyse_python(path, text, ctx, deps)
        else:
            analyse_shell(path, text, ctx, deps)
        ctx.cache[path] = deps.sorted()
    return ctx.cache[path]


def is_expandable(dep):
    if dep.kind == "script" and dep.path:
        return script_language(dep.path) is not None
    return dep.kind == "module" and dep.status == "local" and dep.path.endswith(".py")


def format_lines(lines):
    numbers = sorted(lines)
    text = ", ".join(str(n) for n in numbers[:6])
    return f"l. {text}, ..." if len(numbers) > 6 else f"l. {text}"


#def describe(dep, ctx):
#    text = f"[{dep.kind:<7}] {dep.name}"
#    if dep.status in PROBLEMS:
#        text += f"   !! {dep.status}"
#    elif dep.kind == "module":
#        text += f"   ({dep.status})"
#    if dep.path:
#        text += f"   -> {ctx.show(dep.path)}"
#    if dep.note:
#        text += f"   ({dep.note})"
#    return f"{text}   [{format_lines(dep.lines)}]"
def describe(dep, ctx):
    # When the file name is already visible at the end of the path, show only the path
    if dep.path and os.path.basename(dep.path) == dep.name:
        text = f"[{dep.kind:<7}] -> {ctx.show(dep.path)}"
    else:
        text = f"[{dep.kind:<7}] {dep.name}"
        if dep.path:
            text += f"   -> {ctx.show(dep.path)}"
    if dep.status in PROBLEMS:
        text += f"   !! {dep.status}"
    elif dep.kind == "module":
        text += f"   ({dep.status})"
    if dep.note:
        text += f"   ({dep.note})"
    return f"{text}  [{format_lines(dep.lines)}]"


def is_listed(dep, verbose):
    """By default only scripts and Python modules are listed; with -v everything is."""
    return verbose or dep.kind in ("script", "module")


def write_tree(out, ctx, path, depth, ancestors, listed, verbose):
    """Write the dependencies of a script, then recursively those of its scripts.
    A script already expanded in this tree is not expanded again, so the output stays
    readable and finite even when many scripts call each other."""
    for dep in analyse(path, ctx):
        if not is_listed(dep, verbose):
            continue
        line = "    " * depth + describe(dep, ctx)
        child = dep.path if is_expandable(dep) else None
        if child in ancestors:
            line += "   <circular call>"
            child = None
        elif child in listed:
            line += "   <dependencies listed above>"
            child = None
        out.write(line + "\n")
        if child:
            listed.add(child)
            write_tree(out, ctx, child, depth + 1, ancestors | {child}, listed, verbose)


def write_summary(out, ctx):
    out.write("=" * 90 + "\nTO BE CHECKED BY HAND\n" + "=" * 90 + "\n\n")
    sections = [
        ("Scripts referenced but found neither in the tree nor in the PATH",
         lambda d: d.kind == "script" and d.status == "MISSING"),
        (f"Python modules not importable by {sys.executable}",
         lambda d: d.kind == "module" and d.status == "MISSING"),
        ("Local modules not where Python looks for them",
         lambda d: d.kind == "module" and bool(d.note)),
        ("Words in command position that are neither a builtin, a function, a script, nor in the PATH",
         lambda d: d.status == "UNRESOLVED"),
        ("Calls that cannot be resolved without running the script (eval)",
         lambda d: d.status == "DYNAMIC"),
    ]
    for title, selected in sections:
        found = {}
        for path in sorted(ctx.cache):
            for dep in ctx.cache[path]:
                if selected(dep):
                    found.setdefault(dep.name, []).append(f"{ctx.show(path)} [{format_lines(dep.lines)}]")
        out.write(f"{title}: {len(found)}\n")
        for name in sorted(found):
            out.write(f"    {name}\n" + "".join(f"        <- {where}\n" for where in found[name]))
        out.write("\n")

    out.write(f"Parsing warnings: {sum(len(v) for v in ctx.warnings.values())}\n")
    for path in sorted(ctx.warnings):
        for message in ctx.warnings[path]:
            out.write(f"    {ctx.show(path)}: {message}\n")


def main():
    parser = argparse.ArgumentParser(
        description="List, as a tree, the dependencies of a shell or Python script, or of all "
                    "the scripts of the current directory and its sub-directories.")
    parser.add_argument("script", nargs="?",
                        help="script to check (default: all the scripts of the current directory)")
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="also list commands and dynamic calls (default: scripts and modules only)")
    args = parser.parse_args()

    print(f"\n{PRG} {VER}, {AUT}\n")
    root = os.getcwd()
    ctx = Context(root)              # scripts of the current directory, to resolve names

    if args.script:
        script = os.path.abspath(args.script)
        if not os.path.isfile(script):
            sys.exit(f"{args.script}: no such file")
        if script_language(script) is None:
            sys.exit(f"{args.script}: not a shell or Python script")
        scripts = [script]
    else:
        scripts = ctx.scripts

    out = sys.stdout
    out.write(f"Dependencies of {len(scripts)} script(s); names resolved in {root}\n")
    out.write(f"Commands resolved with the PATH of the session, modules with {sys.executable}\n\n")
    for script in scripts:
        out.write(f"{ctx.show(script)}:\n")
        if not any(is_listed(dep, args.verbose) for dep in analyse(script, ctx)):
            out.write("    (no dependency found)\n")
        write_tree(out, ctx, script, 1, {script}, {script}, args.verbose)
        out.write("\n")
    write_summary(out, ctx)

    problems = sum(1 for deps in ctx.cache.values() for d in deps if d.status in PROBLEMS)
    print(f"\n{len(scripts)} script(s) analysed, {problems} item(s) to check by hand\n")


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:          # output piped to head or less, closed before the end
        os.dup2(os.open(os.devnull, os.O_WRONLY), sys.stdout.fileno())
        sys.exit(1)