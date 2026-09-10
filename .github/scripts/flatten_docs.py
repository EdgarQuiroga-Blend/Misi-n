#!/usr/bin/env python3
"""Aplana README.md + docs/**/*.md a nombres de página planos para GitHub
Wiki (namespace plano) y genera un _Sidebar.md con navegación jerárquica.

Implementa el algoritmo descrito en rag-wiki-architecture-guide.md §8/§27.2,
escrito de forma genérica aunque hoy docs/ solo tenga un archivo (sources.md)
— así sigue funcionando si la documentación crece con subcarpetas.

Uso:
    python3 .github/scripts/flatten_docs.py --repo-root . --out-dir wiki-out
"""
import argparse
import re
import shutil
from pathlib import Path

README_NAMES = {"readme.md", "index.md"}
LINK_RE = re.compile(r"\[([^\]]*)\]\(([^)]+)\)")


def slugify(name: str) -> str:
    stem = Path(name).stem if name.lower().endswith(".md") else name
    slug = re.sub(r"\s+", "-", stem.strip())
    slug = re.sub(r"-{2,}", "-", slug)
    return slug


def collect_markdown_files(repo_root: Path) -> list[Path]:
    files = []
    readme = repo_root / "README.md"
    if readme.exists():
        files.append(readme)
    docs_dir = repo_root / "docs"
    if docs_dir.exists():
        files.extend(sorted(docs_dir.rglob("*.md")))
    return files


def build_flat_name_map(repo_root: Path, files: list[Path]) -> dict[Path, str]:
    docs_dir = repo_root / "docs"
    folder_names = {slugify(p.parent.name) for p in files if p.name.lower() in README_NAMES and p.parent != docs_dir}

    name_map: dict[Path, str] = {}
    for f in files:
        if f == repo_root / "README.md":
            name_map[f] = "Home"
        elif f.name.lower() in README_NAMES:
            name_map[f] = "Home" if f.parent == docs_dir else slugify(f.parent.name)
        else:
            stem = slugify(f.name)
            name_map[f] = f"{slugify(f.parent.name)}-{stem}" if stem in folder_names else stem
    return name_map


def build_link_indexes(repo_root: Path, name_map: dict[Path, str]) -> tuple[dict, dict]:
    path_index, stem_index = {}, {}
    for path, flat_name in name_map.items():
        rel = path.relative_to(repo_root).as_posix().lower()
        path_index[rel] = flat_name
        stem_index[slugify(path.name)] = flat_name
    return path_index, stem_index


def resolve_link(source_file: Path, target: str, repo_root: Path, path_index: dict, stem_index: dict) -> str | None:
    if re.match(r"^(https?:|mailto:)", target) or target.startswith("#"):
        return None
    target_path, _, anchor = target.partition("#")
    if not target_path:
        return None
    if not target_path.lower().endswith(".md"):
        return None

    resolved = (source_file.parent / target_path).resolve()
    try:
        rel = resolved.relative_to(repo_root.resolve()).as_posix().lower()
    except ValueError:
        return None

    flat_name = path_index.get(rel)
    if flat_name is None:
        flat_name = stem_index.get(slugify(Path(target_path).name))
    if flat_name is None:
        return None
    return f"{flat_name}#{anchor}" if anchor else flat_name


def rewrite_links(text: str, source_file: Path, repo_root: Path, path_index: dict, stem_index: dict) -> str:
    def replace(match: re.Match) -> str:
        label, target = match.group(1), match.group(2)
        resolved = resolve_link(source_file, target, repo_root, path_index, stem_index)
        return f"[{label}]({resolved})" if resolved else match.group(0)

    return LINK_RE.sub(replace, text)


def flatten(repo_root: Path, out_dir: Path) -> dict[Path, str]:
    files = collect_markdown_files(repo_root)
    name_map = build_flat_name_map(repo_root, files)
    path_index, stem_index = build_link_indexes(repo_root, name_map)

    out_dir.mkdir(parents=True, exist_ok=True)
    for path, flat_name in name_map.items():
        text = path.read_text(encoding="utf-8")
        text = rewrite_links(text, path, repo_root, path_index, stem_index)
        (out_dir / f"{flat_name}.md").write_text(text, encoding="utf-8")

    images_dir = repo_root / "docs" / "images"
    if images_dir.exists():
        shutil.copytree(images_dir, out_dir / "images", dirs_exist_ok=True)

    return name_map


def generate_sidebar(repo_root: Path, name_map: dict[Path, str]) -> str:
    lines = ["- [Home](Home)"]
    docs_dir = repo_root / "docs"
    if not docs_dir.exists():
        return "\n".join(lines) + "\n"

    for path in sorted(p for p in name_map if p != repo_root / "README.md"):
        rel = path.relative_to(docs_dir)
        depth = len(rel.parts) - 1
        title = path.stem.replace("-", " ").replace("_", " ").title()
        flat_name = name_map[path]
        lines.append(f"{'  ' * depth}- [{title}]({flat_name})")

    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--out-dir", required=True)
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    out_dir = Path(args.out_dir).resolve()

    name_map = flatten(repo_root, out_dir)
    sidebar = generate_sidebar(repo_root, name_map)
    (out_dir / "_Sidebar.md").write_text(sidebar, encoding="utf-8")

    print(f"✅ {len(name_map)} página(s) generadas en {out_dir}")


if __name__ == "__main__":
    main()
