#!/usr/bin/env python3
"""
Add descriptions to blog post front matter.

このスクリプトは、descriptionフィールドがないブログ記事に対して、
本文を要約したdescriptionを追加します。
"""

import os
import re
import sys
from pathlib import Path
from typing import Optional, Tuple


def extract_front_matter_and_content(text: str) -> Tuple[Optional[str], Optional[str]]:
    """
    Extract YAML front matter and content from markdown file.
    
    Returns:
        Tuple of (front_matter, content) or (None, None) if no front matter found
    """
    # Check if file starts with ---
    if not text.startswith('---\n'):
        return None, None
    
    # Find the closing --- (the first occurrence after the opening ---)
    # Remove the opening ---
    text_after_opening = text[4:]  # Remove "---\n"
    
    # Find the first occurrence of \n---\n which closes the front matter
    closing_index = text_after_opening.find('\n---\n')
    if closing_index == -1:
        return None, None
    
    front_matter = text_after_opening[:closing_index]
    content = text_after_opening[closing_index + 5:]  # Skip the \n---\n
    
    return front_matter, content


def has_description(front_matter: str) -> bool:
    """
    Check if front matter already has a non-empty description.
    
    Returns:
        True if description exists and is not empty/null
    """
    for line in front_matter.split('\n'):
        if line.startswith('description:'):
            value = line.split(':', 1)[1].strip()
            # Check if empty or ~
            if value and value != '~':
                return True
    return False


def generate_description(content: str, title: str) -> str:
    """
    Generate a description summary from the content.
    
    Args:
        content: The blog post content
        title: The blog post title
    
    Returns:
        A summary description (first sentence or paragraph, max 100 chars)
    """
    # Remove markdown formatting
    clean_content = re.sub(r'```[\s\S]*?```', '', content)  # Remove code blocks
    clean_content = re.sub(r'`[^`]+`', '', clean_content)  # Remove inline code
    clean_content = re.sub(r'!\[.*?\]\(.*?\)', '', clean_content)  # Remove images
    clean_content = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', clean_content)  # Remove links but keep text
    clean_content = re.sub(r'^#+\s+', '', clean_content, flags=re.MULTILINE)  # Remove headers
    clean_content = re.sub(r'[*_#]', '', clean_content)  # Remove other markdown
    clean_content = re.sub(r'\n\n+', '\n\n', clean_content)  # Normalize paragraphs
    clean_content = clean_content.strip()
    
    # Get first meaningful paragraph (skip common patterns like @nqounet)
    paragraphs = [p.strip() for p in clean_content.split('\n\n') if p.strip()]
    
    description = ""
    for para in paragraphs:
        # Skip author mentions and very short paragraphs
        if para.startswith('@') or len(para) < 20:
            continue
        
        # Use this paragraph, but convert to single line
        description = para
        break
    
    # If no suitable paragraph found, use first non-empty line
    if not description:
        lines = [line.strip() for line in clean_content.split('\n') if line.strip()]
        description = lines[0] if lines else title
    
    # Convert multi-line text to single line
    description = re.sub(r'\s*\n\s*', ' ', description)
    description = re.sub(r'\s+', ' ', description).strip()
    
    # Get first sentence
    sentences = re.split(r'[。\.\!\?]', description)
    if sentences:
        description = sentences[0]
    
    # Ensure it's within 100 characters
    if len(description) > 100:
        description = description[:97] + "..."
    
    return description if description else title


def add_description_to_front_matter(front_matter: str, description: str) -> str:
    """
    Add description field to front matter.
    
    Args:
        front_matter: Original YAML front matter
        description: Description to add
    
    Returns:
        Updated front matter with description
    """
    lines = front_matter.split('\n')
    new_lines = []
    
    # Find where to insert the description (after date or at the beginning)
    inserted = False
    for i, line in enumerate(lines):
        # Replace existing description: ~ line
        if line.startswith('description:'):
            new_lines.append(f'description: "{description}"')
            inserted = True
            continue
        
        new_lines.append(line)
        
        # Insert after date field if not already inserted
        if not inserted and line.startswith('date:'):
            new_lines.append(f'description: "{description}"')
            inserted = True
    
    # If not inserted yet, add at the beginning
    if not inserted:
        new_lines.insert(0, f'description: "{description}"')
    
    return '\n'.join(new_lines)


def extract_title_from_front_matter(front_matter: str) -> str:
    """Extract title from front matter."""
    for line in front_matter.split('\n'):
        if line.startswith('title:'):
            title = line.split(':', 1)[1].strip()
            # Remove quotes if present
            title = title.strip('"\'')
            return title
    return "Untitled"


def process_file(file_path: Path, dry_run: bool = False) -> bool:
    """
    Process a single markdown file to add description.
    
    Args:
        file_path: Path to the markdown file
        dry_run: If True, don't actually modify files
    
    Returns:
        True if file was modified, False otherwise
    """
    try:
        # Read file
        text = file_path.read_text(encoding='utf-8')
        
        # Extract front matter and content
        front_matter, content = extract_front_matter_and_content(text)
        
        if front_matter is None:
            print(f"Skipping {file_path}: No front matter found")
            return False
        
        # Check if description already exists
        if has_description(front_matter):
            return False
        
        # Extract title
        title = extract_title_from_front_matter(front_matter)
        
        # Generate description
        description = generate_description(content, title)
        
        print(f"Processing: {file_path}")
        print(f"  Title: {title}")
        print(f"  Description: {description}")
        
        if dry_run:
            print(f"  [DRY RUN] Would update file")
            return True
        
        # Update front matter
        updated_front_matter = add_description_to_front_matter(front_matter, description)
        
        # Reconstruct file
        updated_text = f"---\n{updated_front_matter}\n---\n{content}"
        
        # Write back
        file_path.write_text(updated_text, encoding='utf-8')
        print(f"  Updated successfully")
        
        return True
        
    except Exception as e:
        print(f"Error processing {file_path}: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return False


def main():
    """Main function to process all blog posts."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Add descriptions to blog posts')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be done without making changes')
    parser.add_argument('--limit', type=int, help='Limit number of files to process')
    parser.add_argument('files', nargs='*', help='Specific files to process (default: all posts)')
    
    args = parser.parse_args()
    
    # Get repository root
    repo_root = Path(__file__).parent.parent
    posts_dir = repo_root / 'content' / 'post'
    
    # Get list of files to process
    if args.files:
        files_to_process = [Path(f) for f in args.files]
    else:
        files_to_process = sorted(posts_dir.glob('**/*.md'))
    
    # Apply limit if specified
    if args.limit:
        files_to_process = files_to_process[:args.limit]
    
    print(f"Found {len(files_to_process)} files to check")
    
    # Process files
    modified_count = 0
    skipped_count = 0
    for file_path in files_to_process:
        result = process_file(file_path, dry_run=args.dry_run)
        if result:
            modified_count += 1
        else:
            skipped_count += 1
    
    print(f"\nSummary:")
    print(f"  Modified: {modified_count} files")
    print(f"  Skipped: {skipped_count} files")


if __name__ == '__main__':
    main()
