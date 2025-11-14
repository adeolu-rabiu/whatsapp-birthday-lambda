#!/usr/bin/env python3

import random

with open('fun_facts_no_blank_lines.txt', 'r') as f:
    facts = [line.strip() for line in f if line.strip()]

print(f"📊 Total fun facts: {len(facts)}\n")
print("🎲 5 Random Fun Facts:\n")
print("=" * 80)

for i, fact in enumerate(random.sample(facts, 5), 1):
    # Remove quotes for display
    clean_fact = fact.strip('"')
    print(f"\n{i}. {clean_fact}")

print("\n" + "=" * 80)
