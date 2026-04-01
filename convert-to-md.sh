#!/bin/bash

# convert-to-md.sh
# Converts all PDF files in the workspace to Markdown using markitdown.

# Check for markitdown CLI
if ! command -v markitdown &> /dev/null; then
    echo "Error: markitdown is not installed. Please install it with: pip install markitdown"
    exit 1
fi

# Define the search directory (default to the parent directory to cover the whole project)
SEARCH_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Scanning for PDFs in: $SEARCH_DIR"

# Find all PDF files and convert them
find "$SEARCH_DIR" -type f -name "*.pdf" -print0 | while IFS= read -r -d '' pdf; do
    md="${pdf%.pdf}.md"
    
    # Skip if markdown already exists and is newer than PDF
    if [[ -f "$md" && "$md" -nt "$pdf" ]]; then
        echo "Skipping (already up to date): $pdf"
        continue
    fi
    
    echo "Converting: $pdf"
    # Execute markitdown and redirect output to the .md file
    markitdown "$pdf" > "$md" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "  Success -> $md"
    else
        echo "  Failed -> $pdf"
        # Clean up empty file if conversion failed
        [ ! -s "$md" ] && rm -f "$md"
    fi
done

echo "Process complete."
