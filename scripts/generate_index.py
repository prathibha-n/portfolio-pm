import os
import re

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
README_PATH = os.path.join(REPO_ROOT, "README.md")
START_MARKER = "<!-- INDEX:START -->"
END_MARKER = "<!-- INDEX:END -->"

EXCLUDE = {".git", ".github", "scripts", "__pycache__"}

def get_title_and_blurb(folder_path):
    readme = os.path.join(folder_path, "README.md")
    if not os.path.exists(readme):
        return None, ""
    with open(readme, encoding="utf-8") as f:
        lines = [l.strip() for l in f if l.strip()]
    title = ""
    blurb = ""
    for line in lines:
        if line.startswith("# ") and not title:
            title = line[2:].strip()
        elif not line.startswith("#") and title:
            blurb = line
            break
    return title, blurb

def build_index():
    rows = []
    for entry in sorted(os.listdir(REPO_ROOT)):
        full_path = os.path.join(REPO_ROOT, entry)
        if not os.path.isdir(full_path) or entry in EXCLUDE or entry.startswith("."):
            continue
        title, blurb = get_title_and_blurb(full_path)
        display_name = title or entry
        rows.append(f"| [{display_name}]({entry}/) | {blurb} |")

    table = "| Project | Summary |\n|---|---|\n" + "\n".join(rows)
    return table

def update_readme():
    with open(README_PATH, encoding="utf-8") as f:
        content = f.read()

    pattern = re.compile(
        re.escape(START_MARKER) + r".*?" + re.escape(END_MARKER),
        re.DOTALL,
    )
    new_block = f"{START_MARKER}\n{build_index()}\n{END_MARKER}"

    if pattern.search(content):
        content = pattern.sub(new_block, content)
    else:
        content += f"\n\n## Case Studies\n\n{new_block}\n"

    with open(README_PATH, "w", encoding="utf-8") as f:
        f.write(content)

if __name__ == "__main__":
    update_readme()
