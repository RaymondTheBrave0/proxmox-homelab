#!/usr/bin/env python3
"""
Script to add metadata to DOCX files for better Nextcloud organization
Uses python-docx library to modify document properties
"""

import os
import sys
import re
import yaml
from datetime import datetime
from pathlib import Path

try:
    from docx import Document
except ImportError:
    print("python-docx not installed. Installing...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "python-docx"])
    from docx import Document

try:
    import yaml
except ImportError:
    print("PyYAML not installed. Installing...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyyaml"])
    import yaml

# Load stopwords from YAML file at module level
def load_stopwords():
    """Load stopwords from YAML file"""
    stopwords_file = Path(__file__).parent / 'stopwords.yml'
    try:
        with open(stopwords_file, 'r') as f:
            data = yaml.safe_load(f)
            return set(data.get('stopwords', []))
    except Exception as e:
        print(f"Warning: Could not load stopwords from {stopwords_file}: {e}")
        print("Using default stopwords list")
        # Fallback to a basic set of stopwords
        return {
            'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'for', 'from',
            'has', 'he', 'in', 'is', 'it', 'its', 'of', 'on', 'that', 'the',
            'to', 'was', 'will', 'with', 'or', 'but', 'not', 'this', 'these',
            'they', 'their', 'what', 'when', 'where', 'who', 'why', 'how',
            'we', 'our', 'us'
        }

# Load stopwords once when module is imported
STOPWORDS = load_stopwords()

def extract_keywords_from_filename(filename):
    """Extract keywords from filename by removing extension and numbers"""
    base = Path(filename).stem
    # Remove leading numbers and hyphen
    base = re.sub(r'^\d+-', '', base)
    # Convert hyphens to spaces
    text = base.replace('-', ' ')
    
    # Split into words and filter out stop words
    words = text.split()
    keywords = [word for word in words if word.lower() not in STOPWORDS]
    
    # Join back into a string
    return ' '.join(keywords) if keywords else text

def determine_category(filename):
    """Determine category based on filename content"""
    lower = filename.lower()
    
    categories = {
        'Calvinism': ['calvinism', 'tulip', 'predestination', 'election'],
        'Eschatology': ['revelation', 'rapture', 'tribulation', 'end-time', 'eschatology', 
                       'second-coming', 'millennium', 'prophecy'],
        'Church Practices': ['baptism', 'communion', 'church', 'assembly', 'worship'],
        'Theology': ['trinity', 'god', 'jesus', 'christ', 'holy-spirit', 'father', 'son'],
        'Biblical Languages': ['hebrew', 'greek', 'translation', 'septuagint', 'aramaic'],
        'Health and Healing': ['healing', 'health', 'vitamin', 'covid', 'vaccine', 'sickness'],
        'Family and Relationships': ['marriage', 'women', 'gender', 'sexuality', 'family'],
        'Apologetics': ['gnosticism', 'false', 'heresy', 'cult', 'error'],
        'Prophecy': ['prophecy', 'daniel', 'prophetic', 'ezekiel', 'isaiah'],
        'Biblical Studies': ['bible', 'scripture', 'study', 'exegesis', 'hermeneutics'],
        'Salvation': ['salvation', 'saved', 'grace', 'faith', 'works'],
        'Death and Resurrection': ['death', 'resurrection', 'soul', 'immortality', 'sheol', 'hades']
    }
    
    for category, keywords in categories.items():
        if any(keyword in lower for keyword in keywords):
            return category
    
    return 'General Theology'

def add_metadata_to_docx(filepath, metadata):
    """Add metadata to a DOCX file"""
    try:
        # Open the document
        doc = Document(filepath)
        
        # Access core properties
        core_props = doc.core_properties
        
        # Update metadata
        core_props.title = metadata.get('title', '')
        core_props.subject = metadata.get('subject', '')
        core_props.author = metadata.get('author', 'Raymond Clements')
        core_props.keywords = metadata.get('keywords', '')
        core_props.category = metadata.get('category', '')
        core_props.comments = metadata.get('description', '')
        
        # Save the document
        doc.save(filepath)
        return True
    except Exception as e:
        print(f"Error processing {filepath}: {str(e)}")
        return False

def process_directory(directory):
    """Process all DOCX files in a directory"""
    directory = Path(directory)
    log_file = Path(f"/home/raymond/Applications/proxmox-homelab/metadata-log-{datetime.now().strftime('%Y%m%d-%H%M%S')}.txt")
    
    with open(log_file, 'w') as log:
        log.write(f"Metadata Addition Log - {datetime.now()}\n")
        log.write("=" * 50 + "\n\n")
        
        docx_files = list(directory.glob("*.docx"))
        total_files = len(docx_files)
        successful = 0
        
        print(f"Found {total_files} DOCX files to process")
        log.write(f"Found {total_files} DOCX files to process\n\n")
        
        for idx, filepath in enumerate(docx_files, 1):
            filename = filepath.name
            print(f"\n[{idx}/{total_files}] Processing: {filename}")
            log.write(f"[{idx}/{total_files}] Processing: {filename}\n")
            
            # Extract metadata from filename
            keywords = extract_keywords_from_filename(filename)
            category = determine_category(filename)
            
            metadata = {
                'title': keywords,
                'subject': category,
                'author': 'Raymond Clements',
                'keywords': keywords,
                'category': category,
                'description': f"Theological document: {keywords}"
            }
            
            print(f"  Title: {metadata['title']}")
            print(f"  Category: {metadata['category']}")
            print(f"  Keywords: {metadata['keywords']}")
            
            log.write(f"  Title: {metadata['title']}\n")
            log.write(f"  Category: {metadata['category']}\n")
            log.write(f"  Keywords: {metadata['keywords']}\n")
            
            # Add metadata
            if add_metadata_to_docx(filepath, metadata):
                print("  ✓ Metadata added successfully")
                log.write("  ✓ Metadata added successfully\n")
                successful += 1
            else:
                print("  ✗ Failed to add metadata")
                log.write("  ✗ Failed to add metadata\n")
            
            log.write("\n")
        
        print(f"\n{'=' * 50}")
        print(f"Processing complete!")
        print(f"Total files: {total_files}")
        print(f"Successful: {successful}")
        print(f"Failed: {total_files - successful}")
        print(f"\nLog saved to: {log_file}")
        
        log.write(f"\n{'=' * 50}\n")
        log.write(f"Processing complete!\n")
        log.write(f"Total files: {total_files}\n")
        log.write(f"Successful: {successful}\n")
        log.write(f"Failed: {total_files - successful}\n")

def verify_metadata(filepath):
    """Verify metadata was added correctly"""
    try:
        doc = Document(filepath)
        props = doc.core_properties
        
        print(f"\nMetadata for: {Path(filepath).name}")
        print(f"  Title: {props.title}")
        print(f"  Subject: {props.subject}")
        print(f"  Author: {props.author}")
        print(f"  Keywords: {props.keywords}")
        print(f"  Category: {props.category}")
        print(f"  Comments: {props.comments}")
        return True
    except Exception as e:
        print(f"Error reading metadata: {str(e)}")
        return False

if __name__ == "__main__":
    docs_dir = "/home/raymond/Documents/posts"
    
    print("DOCX Metadata Addition Tool")
    print("=" * 50)
    print(f"Target directory: {docs_dir}")
    
    # Process all files
    process_directory(docs_dir)
    
    # Verify a sample file
    print("\nVerifying sample file metadata...")
    sample_file = Path(docs_dir) / "0-An-Introduction-to-Calvinism.docx"
    if sample_file.exists():
        verify_metadata(sample_file)
