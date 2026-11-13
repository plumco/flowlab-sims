#!/usr/bin/env python3
"""Add a new simulator to the site.
Usage: python3 add-sim.py my-sim.html --slug cantilever-load --title "Cantilever Load Simulator" \
        --desc "One line about it." --tags "Support,Load"
It copies the HTML to sims/<slug>/index.html and adds a card to sims.js."""
import argparse, json, re, shutil, os, datetime
a = argparse.ArgumentParser()
a.add_argument("file"); a.add_argument("--slug", required=True); a.add_argument("--title", required=True)
a.add_argument("--desc", required=True); a.add_argument("--tags", default="")
x = a.parse_args()
root = os.path.dirname(os.path.abspath(__file__))
dst = os.path.join(root, "sims", x.slug); os.makedirs(dst, exist_ok=True)
html = open(x.file, encoding="utf-8").read()
if "All simulators" not in html:
    html = re.sub(r"(<body[^>]*>)", r'\1\n<a href="../../index.html" style="display:inline-block;margin:8px 12px;font:13px system-ui;color:#1f6feb;text-decoration:none">← All simulators</a>', html, count=1)
open(os.path.join(dst, "index.html"), "w", encoding="utf-8").write(html)
p = os.path.join(root, "sims.js"); src = open(p, encoding="utf-8").read()
data = json.loads(src[src.index("["):src.rindex("]") + 1])
data = [d for d in data if d["slug"] != x.slug]
data.append({"slug": x.slug, "title": x.title, "description": x.desc,
  "tags": [t.strip() for t in x.tags.split(",") if t.strip()], "date": datetime.date.today().isoformat(),
  "path": f"sims/{x.slug}/index.html"})
open(p, "w", encoding="utf-8").write("window.SIMS = " + json.dumps(data, indent=2, ensure_ascii=False) + ";\n")
print("Added:", x.title, "->", f"sims/{x.slug}/index.html")
