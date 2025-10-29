#!/bin/bash

cd /opt/whatsapp-birthday-lambda

echo "🔧 Fixing Dashboard Frontend API URLs"
echo "======================================"
echo ""

# Find all HTML files in dashboard
html_files=$(find dashboard -name "*.html")

if [ -z "$html_files" ]; then
    echo "No HTML files found, checking for template files..."
    html_files=$(find dashboard -name "*.html" -o -name "index.html" -o -name "*.j2")
fi

echo "Found files:"
echo "$html_files"
echo ""

# Replace AWS Lambda URL with local Python API
for file in $html_files; do
    if [ -f "$file" ]; then
        echo "Updating: $file"
        
        # Replace AWS API with local relative path (dashboard will proxy)
        sed -i 's|https://s9i0mo0564.execute-api.eu-west-2.amazonaws.com|http://192.168.1.66:5000|g' "$file"
        
        # Or use relative path if dashboard has proxy
        # sed -i 's|https://s9i0mo0564.execute-api.eu-west-2.amazonaws.com|/api|g' "$file"
        
        echo "✅ Updated"
    fi
done

# Also check Python files that might serve HTML
if [ -f "dashboard/server.py" ]; then
    echo ""
    echo "Checking server.py for hardcoded URLs..."
    grep -n "s9i0mo0564\|apiBase" dashboard/server.py && echo "Found in server.py" || echo "Not found in server.py"
fi

echo ""
echo "✅ Frontend fix complete"
echo ""
echo "Rebuilding dashboard..."
docker-compose build dashboard
docker-compose restart dashboard

sleep 5

echo ""
echo "Dashboard status:"
docker ps | grep dashboard

echo ""
echo "✅ Done! Refresh browser: http://192.168.1.66:8080"
