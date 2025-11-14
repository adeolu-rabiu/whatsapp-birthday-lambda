#!/bin/bash

FILE="fun_facts_no_blank_lines.txt"

echo "📊 Fun Facts Statistics"
echo "======================="
echo ""
echo "Total facts: $(wc -l < $FILE)"
echo "Total characters: $(wc -m < $FILE)"
echo "Average length: $(awk '{total += length} END {print int(total/NR)}' $FILE) chars per fact"
echo ""

# Count facts by theme (rough estimate)
echo "📋 Themes (approximate):"
echo "  Travel/Countries: $(grep -i 'visit\|travel\|country' $FILE | wc -l)"
echo "  Motivation: $(grep -i 'life\|dream\|future\|possible' $FILE | wc -l)"
echo "  Work/Balance: $(grep -i 'work\|balance\|break\|rest' $FILE | wc -l)"
echo "  Culture: $(grep -i 'culture\|tradition\|ritual' $FILE | wc -l)"
echo ""

# Random fact preview
echo "🎲 Random fact:"
shuf -n 1 $FILE | sed 's/"//g'
echo ""
