#!/usr/bin/env python3
"""
Convert stopword list to YAML format
"""

import yaml

# Read the stopword list
with open('/home/raymond/Applications/proxmox-homelab/stopword-list.txt', 'r') as f:
    stopwords = set()
    for line in f:
        word = line.strip()
        if word and not word.startswith('﻿'):  # Skip empty lines and BOM
            # Remove BOM if present
            if word.startswith('﻿'):
                word = word[1:]
            stopwords.add(word.lower())

# Add additional stopwords from the original program that might not be in the list
additional_stopwords = {
    'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'for', 'from',
    'has', 'he', 'in', 'is', 'it', 'its', 'of', 'on', 'that', 'the',
    'to', 'was', 'will', 'with', 'or', 'but', 'not', 'this', 'these',
    'they', 'their', 'what', 'when', 'where', 'who', 'why', 'how',
    'all', 'each', 'few', 'more', 'most', 'other', 'some', 'such',
    'no', 'nor', 'only', 'own', 'same', 'so', 'than', 'too', 'very',
    'can', 'could', 'may', 'might', 'must', 'shall', 'should', 'would',
    'about', 'after', 'before', 'between', 'during', 'through', 'under',
    'up', 'down', 'out', 'off', 'over', 'again', 'then', 'once', 'we'
}

# Merge all stopwords
stopwords.update(additional_stopwords)

# Sort the stopwords alphabetically
sorted_stopwords = sorted(list(stopwords))

# Create YAML structure
data = {
    'stopwords': sorted_stopwords,
    'metadata': {
        'total_count': len(sorted_stopwords),
        'description': 'Comprehensive stopword list for metadata extraction',
        'last_updated': '2025-07-29'
    }
}

# Write to YAML file
with open('/home/raymond/Applications/proxmox-homelab/stopwords.yml', 'w') as f:
    yaml.dump(data, f, default_flow_style=False, sort_keys=False)

print(f"Created stopwords.yml with {len(sorted_stopwords)} stopwords")
