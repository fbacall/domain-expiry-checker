# Usage Examples

This document provides practical examples of using the domain expiry checker.

## Basic Usage

### Check a single domain:
```bash
echo "example.com" | ./domain_expiry_checker.rb
```

### Check multiple domains from a file:
```bash
./domain_expiry_checker.rb domains.txt
```

### Check domains via stdin (useful in scripts):
```bash
cat domains.txt | ./domain_expiry_checker.rb
```

## Creating a Domain List File

Create a text file with one domain per line:

```
example.com
google.com
github.com
stackoverflow.com
```

You can add comments using `#`:

```
# Production domains
example.com
api.example.com

# Development domains
dev.example.com
```

## Output Format

The script outputs tab-separated values that can be easily parsed or imported:

```
example.com     2024-08-13
google.com      2024-09-14
github.com      2025-10-09
```

### Pipe to other tools:

```bash
# Save to CSV
./domain_expiry_checker.rb domains.txt > expiry_dates.tsv

# Sort by domain name instead of expiry date
./domain_expiry_checker.rb domains.txt | sort

# Filter domains expiring soon (requires date parsing)
./domain_expiry_checker.rb domains.txt | grep "2024-01"

# Count domains
./domain_expiry_checker.rb domains.txt | wc -l
```

## Handling Large Domain Lists

The script is memory-efficient and can handle large lists:

```bash
# Process 10,000 domains
./domain_expiry_checker.rb large_domain_list.txt > results.tsv
```

## Error Handling

The script provides clear error messages:

```bash
# Non-existent file
./domain_expiry_checker.rb missing.txt
# Output: Error: File 'missing.txt' not found

# Invalid domain format
echo "not a domain!" | ./domain_expiry_checker.rb
# Output: Warning: Invalid domain format: not a domain!

# Network issues
echo "example.com" | ./domain_expiry_checker.rb
# Output: Warning: Failed to query WHOIS for example.com: [error details]
# Output: example.com	UNKNOWN
```

## Integration Examples

### Cron Job for Monitoring

Create a cron job to check domain expiry dates weekly:

```bash
# Edit crontab
crontab -e

# Add this line (runs every Monday at 9 AM)
0 9 * * 1 /path/to/domain_expiry_checker.rb /path/to/domains.txt | mail -s "Domain Expiry Report" admin@example.com
```

### Shell Script Integration

```bash
#!/bin/bash
# Check if any domains expire within 30 days

RESULTS=$(./domain_expiry_checker.rb domains.txt)

while IFS=$'\t' read -r domain date; do
  if [ "$date" != "UNKNOWN" ]; then
    # Calculate days until expiry (requires date command)
    days_until=$(( ($(date -d "$date" +%s) - $(date +%s)) / 86400 ))
    
    if [ $days_until -lt 30 ]; then
      echo "WARNING: $domain expires in $days_until days ($date)"
    fi
  fi
done <<< "$RESULTS"
```

## Rate Limiting Considerations

WHOIS servers may rate-limit queries. For large lists:

1. Add delays between queries (modify the script if needed)
2. Split large lists into smaller batches
3. Use WHOIS API services for bulk queries

## Tips

- Keep your domain list file under version control
- Run the script regularly to track expiry date changes
- Use the tab-separated format for easy import into spreadsheets
- Combine with `column -t` for prettier terminal output:
  ```bash
  ./domain_expiry_checker.rb domains.txt | column -t
  ```
