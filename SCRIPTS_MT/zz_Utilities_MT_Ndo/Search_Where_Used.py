#!/opt/local/amster_python_env/bin/python
# -----------------------------------------------------------------------------------------
# This script searches in which scripts a command, a script or any other file (data,
# parameter file, list, image...) is used or created, then in which scripts these
# scripts are used, and so on, and lists the result as a tree in the terminal:
#
#   SAR_CSL_SAR.txt is used or created by:
#       ./SomeScript.sh  [l. 120, 133]   (writes it: l. 133)
#           ./SomeCaller.sh  [l. 44, 57]
#               ./MainScript.sh  [l. 12]
#
# A file is found where its name is written in the code as a whole name, possibly after
# a path (${DIR}/SAR_CSL_SAR.txt). "writes it" marks the lines where the file is the
# target of a redirection (> or >>), of tee, or of open(..., "w"/"a"/"x") in Python;
# a file created by another program (cp, mv, gdal_translate -of ... file) is shown as
# used only. A name built at run time (${X}_SAR.txt) cannot be found.
#
# The scripts searched are the shell and Python scripts of $HOME/SAR/AMSTer/SCRIPTS_MT and
# its sub-directories (or of the directory given with -d).
#
# The scripts are read exactly as Search_Dependencies.py reads them (that script is
# taken next to this one if it is there, otherwise from the PATH): comment lines, what
# is only displayed (echo, printf, print; except a redirection target: echo x > file) and 
# calls through variables (${SED}, "$CMD") are ignored.
#
# Parameters are:
#       - name of a command, of a script or of a file (e.g. gdalwarp, PlotTS.sh,
#         SAR_CSL_SAR.txt), or path to a script (e.g. ./zz_Utilities_MT/filtercut.py),
#         which avoids any confusion when several scripts of the tree have the same name.
#         Names may contain the wildcards * ? and [...] (e.g. 'FijiMacro*.txt'); quote
#         them, otherwise the shell expands them before this script sees them. The names
#         that matched are shown after each script of the first level.
#       - optional: -d directory  scripts to search (default: $HOME/SAR/AMSTer/SCRIPTS_MT)
#
#   e.g.  Search_Where_Used.py PlotTS.sh
#         Search_Where_Used.py gdalwarp -d $HOME/SAR/AMSTer/SCRIPTS_MT/zz_Utilities_MT
#         Search_Where_Used.py SAR_CSL_SAR.txt
#         Search_Where_Used.py 'FijiMacro*.txt'
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies: - Python 3.8 or later (AMSTer venv)
#               - Search_Dependencies.py (next to this script, or in the PATH)
#
# New in Distro V 1.0 20261019: - Based on Search_Dependencies.py
#                               - also searches the files used or created by the scripts
#                               - wildcards * ? [...] allowed in the name
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2026/10/19
# -----------------------------------------------------------------------------------------

import argparse
import ast
import fnmatch
import importlib.machinery
import importlib.util
import os
import re
import shutil
import sys

PRG = os.path.basename(sys.argv[0])
VER = "Distro V1.0 AMSTer script utilities"
AUT = "Nicolas d'Oreye, (c)2026, Last modified on Oct 19, 2026"

DEFAULT_DIRECTORY = os.path.expanduser("~/SAR/AMSTer/SCRIPTS_MT")
DEPENDENCIES_NAME = "Search_Dependencies.py"


def find_dependencies_script():
    """Path of Search_Dependencies.py: next to this script if it is there, otherwise the
    one found in the PATH (the one that would run when typing its name)."""
    same_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), DEPENDENCIES_NAME)
    if os.path.isfile(same_dir):
        return same_dir
    in_path = shutil.which(DEPENDENCIES_NAME)
    if in_path:
        return os.path.realpath(in_path)
    sys.exit(f"{DEPENDENCIES_NAME} not found, neither next to {PRG} nor in the PATH")


def load_dependencies_module():
    """Load Search_Dependencies.py as a Python module, to read the scripts the same way."""
    path = find_dependencies_script()
    loader = importlib.machinery.SourceFileLoader("search_dependencies", path)
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    sys.modules[loader.name] = module       # needed by dataclasses while the module loads
    loader.exec_module(module)
    return module


def build_users_index(sd, ctx):
    """Who uses what: {name or path of a dependency: {path of the user script: lines}}.
    A dependency is known by its name (PlotTS.sh, gdalwarp), by its path, and by the file
    name of its path (helper.py for the module helper)."""
    users = {}
    for script in ctx.scripts:
        for dep in sd.analyse(script, ctx):
            keys = {dep.name, dep.path, os.path.basename(dep.path)} - {""}
            for key in keys:
                users.setdefault(key, {}).setdefault(script, set()).update(dep.lines)
    return users


WILDCARD_RE = re.compile(r"[*?\[]")
WILDCARD_SPLIT_RE = re.compile(r"(\*|\?|\[[^\]]+\])")


def name_regex(name):
    """The name as a whole name, possibly after a path: /dir/name, ${DIR}/name, "name".
    Wildcards: * any characters of a file name, ? one of them, [...] one of a set.
    The wildcard characters are themselves accepted, so that a script reading the
    files with the same kind of pattern (ls FijiMacro*.txt) is also found."""
    regex = ""
    for chunk in WILDCARD_SPLIT_RE.split(name):
        if chunk == "*":
            regex += r"[\w.+*?-]*"
        elif chunk == "?":
            regex += r"[\w.+*?-]"
        elif chunk.startswith("[") and len(chunk) > 2:
            regex += "[^" + chunk[2:] if chunk.startswith("[!") else chunk
        else:
            regex += re.escape(chunk)
    if name[:1] in ("*", "?", "["):
        regex = r"(?!\.)" + regex                       # like the shell: * does not match .name
    return re.compile(r"(?<![\w.+-])(" + regex + r")(?![\w+-]|\.\w)")


def literal_part(name):
    """Longest part of the name without wildcard, for a quick test before parsing."""
    return max(WILDCARD_SPLIT_RE.split(name)[::2], key=len)


def shell_mentions(sd, text, pattern):
    """{line: written?} of the lines of shell code where the file name is written, except
    in what echo or printf only display (unless it is where they write), and the set of
    the names that matched."""
    found, names = {}, set()
    text, heredoc_lines = sd.split_heredocs(text)
    _, view, strings = sd.scan_shell(text)
    for lineno, words in sd.simple_commands(view):
        commands = [w.rsplit("/", 1)[-1] for w in sd.commands_in(words)]
        displayed = any(c in sd.DISPLAY_COMMANDS for c in commands)
        for index, word in enumerate(words):
            word_text = sd.QUOTED_RE.sub(lambda m: strings[int(m.group(1))], word)
            matches = pattern.findall(word_text)
            if not matches:
                continue
            written = (word.startswith(">") or (index > 0 and words[index - 1] in (">", ">>"))
                       or ("tee" in commands and word.rsplit("/", 1)[-1] != "tee"))
            if written or not displayed:
                found[lineno] = found.get(lineno, False) or written
                names.update(matches)
    for lineno, line in heredoc_lines:                  # input given to other programs
        matches = pattern.findall(line)
        if matches:
            found.setdefault(lineno, False)
            names.update(matches)
    return found, names


def python_mentions(text, pattern):
    """{line: written?} of the lines of Python code where the file name is written in a
    string, except in docstrings and in what print() only displays, and the set of the
    names that matched."""
    found, names = {}, set()
    try:
        tree = ast.parse(text)
    except (SyntaxError, ValueError):                   # e.g. Python 2: line by line
        for lineno, line in enumerate(text.split("\n"), 1):
            matches = pattern.findall(re.sub(r"(^|\s)#.*", "", line))
            if matches and not re.match(r"\s*print\b", line):
                found[lineno] = False
                names.update(matches)
        return found, names
    displayed, written = set(), set()
    for node in ast.walk(tree):
        if isinstance(node, (ast.Module, ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)) and node.body:
            first = node.body[0]                        # docstring: documentation, like a comment
            if isinstance(first, ast.Expr) and isinstance(first.value, ast.Constant):
                displayed.add(id(first.value))
        if not isinstance(node, ast.Call):
            continue
        name = getattr(node.func, "id", getattr(node.func, "attr", ""))
        if name == "print":
            displayed.update(id(part) for part in ast.walk(node))
        elif name == "open" and node.args:
            mode = node.args[1] if len(node.args) > 1 else next(
                (k.value for k in node.keywords if k.arg == "mode"), None)
            if isinstance(mode, ast.Constant) and re.search(r"[wax]", str(mode.value)):
                written.update(id(part) for part in ast.walk(node.args[0]))
    for node in ast.walk(tree):
        if isinstance(node, ast.Constant) and isinstance(node.value, str) and id(node) not in displayed:
            matches = pattern.findall(node.value)
            if matches:
                found[node.lineno] = found.get(node.lineno, False) or id(node) in written
                names.update(matches)
    return found, names


def file_mentions(sd, ctx, name):
    """Scripts where a file name (wildcards allowed) is written:
    {script: lines}, {script: lines writing it}, {script: names that matched}."""
    pattern = name_regex(name)
    literal = literal_part(name)
    used, written, matched = {}, {}, {}
    for script in ctx.scripts:
        text = sd.read_text(script)
        if literal not in text:                         # quick test before parsing
            continue
        if sd.script_language(script) == "python":
            found, names = python_mentions(text, pattern)
        else:
            found, names = shell_mentions(sd, text, pattern)
        if names:
            matched.setdefault(script, set()).update(names)
        for lineno, is_written in found.items():
            used.setdefault(script, set()).add(lineno)
            if is_written:
                written.setdefault(script, set()).add(lineno)
    return used, written, matched


def write_users(sd, ctx, users, found, written, matched, depth, ancestors, listed):
    """Write the scripts in `found` ({script: lines}), each one followed by the scripts
    using it (recursively). A script already expanded is not expanded again, so the
    output stays finite."""
    for user in sorted(found):
        line = "    " * depth + f"{ctx.show(user)}  [{sd.format_lines(found[user])}]"
        if written.get(user):
            line += f"   (writes it: {sd.format_lines(written[user])})"
        if matched.get(user):
            line += "   {" + ", ".join(sorted(matched[user])) + "}"
        if user in ancestors:
            print(line + "   <circular call>")
        elif user in listed:
            print(line + "   <users listed above>")
        else:
            print(line)
            listed.add(user)
            write_users(sd, ctx, users, users.get(user, {}), {}, {}, depth + 1, ancestors | {user}, listed)


def main():
    parser = argparse.ArgumentParser(
        description="List, as a tree, the scripts that use a command or a script, the scripts "
                    "that use these ones, and so on.")
    parser.add_argument("target", help="command or script name, or path to a script")
    parser.add_argument("-d", "--directory", default=DEFAULT_DIRECTORY,
                        help=f"scripts to search (default: {DEFAULT_DIRECTORY})")
    args = parser.parse_args()

    print(f"\n{PRG} {VER}, {AUT}\n")
    root = os.path.abspath(args.directory)
    if not os.path.isdir(root):
        sys.exit(f"{args.directory}: no such directory")

    sd = load_dependencies_module()
    sd.SYSTEM_COMMAND_DIRS = set()          # here, also find the users of ls, grep, rm...
    ctx = sd.Context(root)
    users = build_users_index(sd, ctx)

    # A path to an existing file is matched by path (exact); anything else by name
    if os.path.isfile(args.target):
        key = os.path.abspath(args.target)
    else:
        key = os.path.basename(args.target)

    # First level: scripts calling it (script, command, module) and scripts where its
    # name is written (any file: data, parameters, lists...)
    name = os.path.basename(args.target)
    wildcards = WILDCARD_RE.search(name) is not None
    if wildcards:                                       # all the names matching the pattern
        keys = [k for k in users if "/" not in k and fnmatch.fnmatchcase(k, name)]
    else:
        keys = [key]
    found, matched = {}, {}
    for k in keys:
        for user, lines in users.get(k, {}).items():
            found.setdefault(user, set()).update(lines)
            matched.setdefault(user, set()).add(k)
    used, written, mentioned = file_mentions(sd, ctx, name)
    for user, lines in used.items():
        found.setdefault(user, set()).update(lines)
        matched.setdefault(user, set()).update(mentioned.get(user, set()))
    if not wildcards:
        matched = {}                                    # one name only: nothing to show

    print(f"Searched in the {len(ctx.scripts)} scripts of {root}\n")
    if not found:
        print(f"{args.target} is not used or created by any of these scripts\n")
        return
    print(f"{args.target} is used or created by:")
    write_users(sd, ctx, users, found, written, matched, 1, {key}, set())
    print()


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:          # output piped to head or less, closed before the end
        os.dup2(os.open(os.devnull, os.O_WRONLY), sys.stdout.fileno())
        sys.exit(1)