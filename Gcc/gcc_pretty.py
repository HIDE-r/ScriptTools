#!/usr/bin/env python3
import shlex
import sys

line = sys.stdin.read().strip()
argv = shlex.split(line)

cc = argv[0]
args = argv[1:]

incs = []
defs = []
warns = []
debug = []
optimization = []
opts = []
libs = []
libpaths = []
objs = []
others = []
cmds = []  # -c -S -E -o 及其参数归这里

out = None

i = 0
while i < len(args):
    a = args[i]

    # 输出文件
    if a == "-o" and i + 1 < len(args):
        out = args[i + 1]
        cmds.append(a)
        i += 2
        continue
    # 源文件
    elif a.endswith(".c"):
        objs.append(a)
    # 头文件目录
    elif a.startswith("-I"):
        incs.append(a)
    # 宏定义
    elif a.startswith("-D"):
        defs.append(a)
    # 警告选项
    elif a.startswith("-W") or a.startswith("-w"):
        warns.append(a)
    # 调试选项
    elif a.startswith("-g"):
        debug.append(a)
    # 优化选项
    elif a.startswith("-O"):
        optimization.append(a)
    # 静态/目标文件
    elif a.endswith(".o") or a.endswith(".a"):
        objs.append(a)
    # 库路径
    elif a.startswith("-L"):
        libpaths.append(a)
    # 链接库
    elif a.startswith("-l"):
        libs.append(a)
    # 编译/预处理/汇编/输出文件选项
    elif a in ("-c", "-S", "-E"):
        cmds.append(a)
    # 其他 gcc 参数
    elif a.startswith("-"):
        opts.append(a)
    else:
        others.append(a)

    i += 1

print(f"[GCC] {cc}\n")

if cmds:
    print("\n  CMD :", " ".join(cmds))

if out:
    print("  OUT :", out)

if objs:
    print("\n  OBJ :")
    for x in objs:
        print("   ", x)

if incs:
    print("\n  INC :")
    for x in incs:
        print("   ", x)

if defs:
    print("\n  DEF :")
    for x in defs:
        print("   ", x)

if libpaths:
    print("\n  LIBPATH :")
    for x in libpaths:
        print("   ", x)

if libs:
    print("\n  LIB :")
    for x in libs:
        print("   ", x)

if warns:
    print("\n  WARN :", " ".join(warns))

if debug:
    print("\n  DBG :", " ".join(debug))

if optimization:
    print("\n  OPTI :", " ".join(optimization))

if opts:
    print("\n  OPT :", " ".join(opts))

if others:
    print("\n  OTHER :", " ".join(others))

