# summary.py RESULT_FILES...: a Markdown table of medians per runner, variant and JIT setting
import sys, os, statistics, collections
rows = collections.defaultdict(list)
for path in sys.argv[1:]:
    runner = os.path.basename(os.path.dirname(path)) or path
    for line in open(path):
        f = line.split()
        if len(f) != 7 or not f[2].isdigit():
            continue
        v, jit, rep, c, m, i, rc = f
        if rc != "0":
            rows[(runner, jit, v)].append(None)
            continue
        rows[(runner, jit, v)].append((float(c), float(m), float(i)))
print("| runner | jit | variant | builds | configure | make | install | total | speedup |")
print("|---|---|---|---|---|---|---|---|---|")
for (runner, jit) in sorted({(r, j) for r, j, _ in rows}):
    tot = {}
    for v in ("baseline", "candidate"):
        ok = [x for x in rows.get((runner, jit, v), []) if x]
        n = len(rows.get((runner, jit, v), []))
        if not ok:
            print(f"| {runner} | {jit} | {v} | 0/{n} | | | | | |")
            continue
        med = [statistics.median(x[k] for x in ok) for k in range(3)]
        tot[v] = statistics.median(sum(x) for x in ok)
        sp = f"{tot['baseline'] / tot[v]:.2f}x" if v == "candidate" and "baseline" in tot else ""
        print(f"| {runner} | {jit} | {v} | {len(ok)}/{n} | {med[0]:.1f} | {med[1]:.1f} | {med[2]:.1f} | {tot[v]:.1f} | {sp} |")
