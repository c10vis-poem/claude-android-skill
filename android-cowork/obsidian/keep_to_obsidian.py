#!/usr/bin/env python3
"""
Convert Google Keep HTML export to Obsidian markdown notes.

Usage:
  1. Download your Keep data from takeout.google.com
  2. Extract the zip file
  3. Run: python3 keep_to_obsidian.py /path/to/Takeout/Keep /path/to/vault/Imports

Install dependency first:
  pip install markdownify
"""

import os
import sys
import re
from pathlib import Path
from datetime import datetime

try:
    from markdownify import markdownify as md
except ImportError:
    print("Install dependency first:")
    print("  pip install markdownify")
    sys.exit(1)


def sanitize_filename(name):
    """Make a string safe for use as a filename."""
    name = re.sub(r'[<>:"/\\|?*]', '', name)
    name = name.strip('. ')
    return name[:80] if name else 'Untitled'


def convert_keep_html(html_path, output_dir):
    """Convert a single Keep HTML file to a markdown note."""
    with open(html_path, 'r', encoding='utf-8') as f:
        html = f.read()

    # Extract title
    title_match = re.search(r'<div class="title">(.*?)</div>', html, re.DOTALL)
    title = title_match.group(1).strip() if title_match else ''
    title = re.sub(r'<[^>]+>', '', title).strip()

    # Extract content
    content_match = re.search(r'<div class="content">(.*?)</div>', html, re.DOTALL)
    content_html = content_match.group(1) if content_match else ''

    # Extract labels
    labels = re.findall(r'<span class="label-name">(.*?)</span>', html)

    # Extract date from filename (Keep uses timestamp filenames)
    date_match = re.search(r'(\d{4}-\d{2}-\d{2})', html_path.name)
    date_str = date_match.group(1) if date_match else datetime.now().strftime('%Y-%m-%d')

    # Convert to markdown
    body = md(content_html).strip()

    # Build frontmatter
    frontmatter = f"""---
source: google-keep
imported: {datetime.now().strftime('%Y-%m-%d')}
date: {date_str}
"""
    if labels:
        frontmatter += "tags:\n"
        for label in labels:
            frontmatter += f"  - {label.lower().replace(' ', '-')}\n"
frontmatter += "---\n\n"

    # Build note content
    if title:
        note = frontmatter + f"# {title}\n\n{body}\n"
        filename = sanitize_filename(title) + '.md'
    else:
        note = frontmatter + body + '\n'
        filename = sanitize_filename(date_str + ' Keep Note') + '.md'

    # Write output
    output_path = output_dir / filename
    # Handle duplicates
    counter = 1
    while output_path.exists():
        stem = sanitize_filename(title or date_str)
        output_path = output_dir / f"{stem} ({counter}).md"
        counter += 1

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(note)

    return output_path.name


def main():
    if len(sys.argv) < 3:
        print("Usage: python3 keep_to_obsidian.py <keep-folder> <output-folder>")
        print("")
        print("Example:")
        print("  python3 keep_to_obsidian.py ~/Downloads/Takeout/Keep ~/storage/shared/N0VA/Imports")
        sys.exit(1)

    keep_dir = Path(sys.argv[1])
    output_dir = Path(sys.argv[2])

    if not keep_dir.exists():
        print(f"Keep folder not found: {keep_dir}")
        sys.exit(1)

    output_dir.mkdir(parents=True, exist_ok=True)

    html_files = list(keep_dir.glob('*.html'))
    if not html_files:
        print(f"No HTML files found in {keep_dir}")
        sys.exit(1)

    print(f"Found {len(html_files)} Keep notes. Converting...")
    print("")

    converted = 0
    errors = 0

    for html_file in sorted(html_files):
        try:
            out_name = convert_keep_html(html_file, output_dir)
            print(f"  OK  {out_name}")
            converted += 1
        except Exception as e:
            print(f"  ERR {html_file.name}: {e}")
            errors += 1

    print("")
    print(f"Done. {converted} converted, {errors} errors.")
    print(f"Notes saved to: {output_dir}")
    print("")
    print("Open Obsidian and look in the Imports/ folder.")


if __name__ == '__main__':
    main()
