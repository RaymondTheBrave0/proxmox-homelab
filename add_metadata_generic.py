#!/usr/bin/env python3
"""
Generic metadata extractor and updater for multiple file types
Supports DOCX, images, videos, and audio files
"""

import os
import sys
import re
import yaml
import subprocess
from datetime import datetime
from pathlib import Path

# Try to import required libraries
try:
    from docx import Document
except ImportError:
    Document = None

# Load stopwords from YAML file at module level
def load_stopwords():
    """Load stopwords from YAML file"""
    stopwords_file = Path(__file__).parent / 'stopwords.yml'
    try:
        with open(stopwords_file, 'r') as f:
            data = yaml.safe_load(f)
            stopwords = set(data.get('stopwords', []))
            print(f"Loaded {len(stopwords)} stopwords from {stopwords_file}")
            return stopwords
    except Exception as e:
        print(f"Warning: Could not load stopwords from {stopwords_file}: {e}")
        print("Using default stopwords list")
        return set()

# Load stopwords once when module is imported
STOPWORDS = load_stopwords()

def extract_keywords_from_filename(filename):
    """Extract keywords from filename by removing extension and numbers"""
    base = Path(filename).stem
    # Remove leading numbers and hyphen
    base = re.sub(r'^\d+[-_]', '', base)
    # Convert hyphens and underscores to spaces
    text = base.replace('-', ' ').replace('_', ' ')
    
    # Split into words and filter out stop words
    words = text.split()
    keywords = [word for word in words if word.lower() not in STOPWORDS]
    
    # Join back into a string
    return ' '.join(keywords) if keywords else text

def add_docx_metadata(filepath, metadata):
    """Add metadata to DOCX files using python-docx"""
    if Document is None:
        print("python-docx not available. Install with: pip install python-docx")
        return False
        
    try:
        doc = Document(filepath)
        core_props = doc.core_properties
        
        core_props.title = metadata.get('title', '')
        core_props.subject = metadata.get('subject', '')
        core_props.author = metadata.get('author', '')
        core_props.keywords = metadata.get('keywords', '')
        core_props.category = metadata.get('category', '')
        core_props.comments = metadata.get('description', '')
        
        doc.save(filepath)
        return True
    except Exception as e:
        print(f"Error processing DOCX {filepath}: {str(e)}")
        return False

def add_exif_metadata(filepath, metadata):
    """Add metadata to images/videos/audio using exiftool"""
    try:
        # Check if exiftool is installed
        result = subprocess.run(['which', 'exiftool'], capture_output=True)
        if result.returncode != 0:
            print("exiftool not found. Install with: sudo apt install libimage-exiftool-perl")
            return False
        
        # Build exiftool command
        cmd = ['exiftool', '-overwrite_original']
        
        # Add metadata fields that exiftool supports
        if metadata.get('title'):
            cmd.extend(['-Title=' + metadata['title']])
        if metadata.get('keywords'):
            cmd.extend(['-Keywords=' + metadata['keywords']])
        if metadata.get('subject'):
            cmd.extend(['-Subject=' + metadata['subject']])
        if metadata.get('author'):
            cmd.extend(['-Artist=' + metadata['author']])
            cmd.extend(['-Author=' + metadata['author']])
        if metadata.get('description'):
            cmd.extend(['-Description=' + metadata['description']])
            cmd.extend(['-Comment=' + metadata['description']])
        if metadata.get('category'):
            cmd.extend(['-Category=' + metadata['category']])
        
        cmd.append(str(filepath))
        
        # Run exiftool
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            return True
        else:
            print(f"Exiftool error: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"Error processing with exiftool {filepath}: {str(e)}")
        return False

def process_file(filepath):
    """Process a single file and add metadata based on filename"""
    filepath = Path(filepath)
    
    # Extract metadata from filename
    keywords = extract_keywords_from_filename(filepath.name)
    
    metadata = {
        'title': keywords,
        'keywords': keywords,
        'author': 'Raymond Clements',
        'subject': 'General',
        'category': 'General',
        'description': f"File: {keywords}"
    }
    
    # Determine file type and process accordingly
    ext = filepath.suffix.lower()
    
    # Document files
    if ext in ['.docx']:
        print(f"Processing DOCX: {filepath.name}")
        return add_docx_metadata(filepath, metadata)
    
    # Image files
    elif ext in ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp']:
        print(f"Processing Image: {filepath.name}")
        metadata['description'] = f"Image: {keywords}"
        return add_exif_metadata(filepath, metadata)
    
    # Video files
    elif ext in ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm']:
        print(f"Processing Video: {filepath.name}")
        metadata['description'] = f"Video: {keywords}"
        return add_exif_metadata(filepath, metadata)
    
    # Audio files
    elif ext in ['.mp3', '.wav', '.flac', '.ogg', '.m4a', '.wma', '.aac']:
        print(f"Processing Audio: {filepath.name}")
        metadata['description'] = f"Audio: {keywords}"
        return add_exif_metadata(filepath, metadata)
    
    else:
        print(f"Unsupported file type: {ext}")
        return False

def process_directory(directory, extensions=None):
    """Process all supported files in a directory"""
    directory = Path(directory)
    
    # Default extensions if none specified
    if extensions is None:
        extensions = [
            '.docx', '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp',
            '.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm',
            '.mp3', '.wav', '.flac', '.ogg', '.m4a', '.wma', '.aac'
        ]
    
    # Find all matching files
    files = []
    for ext in extensions:
        files.extend(directory.glob(f"*{ext}"))
        files.extend(directory.glob(f"*{ext.upper()}"))
    
    total = len(files)
    successful = 0
    
    print(f"\nFound {total} files to process")
    print("=" * 50)
    
    for idx, filepath in enumerate(files, 1):
        print(f"\n[{idx}/{total}] {filepath.name}")
        print(f"  Keywords: {extract_keywords_from_filename(filepath.name)}")
        
        if process_file(filepath):
            print("  ✓ Metadata added successfully")
            successful += 1
        else:
            print("  ✗ Failed to add metadata")
    
    print("\n" + "=" * 50)
    print(f"Processing complete!")
    print(f"Total files: {total}")
    print(f"Successful: {successful}")
    print(f"Failed: {total - successful}")

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Add metadata to files based on filename')
    parser.add_argument('path', help='File or directory to process')
    parser.add_argument('--extensions', nargs='+', help='File extensions to process (e.g., .docx .jpg)')
    
    args = parser.parse_args()
    
    path = Path(args.path)
    
    if path.is_file():
        # Process single file
        if process_file(path):
            print(f"✓ Successfully added metadata to {path.name}")
        else:
            print(f"✗ Failed to add metadata to {path.name}")
    elif path.is_dir():
        # Process directory
        process_directory(path, args.extensions)
    else:
        print(f"Error: {path} does not exist")
        sys.exit(1)
