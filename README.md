# domain-expiry-checker

A Ruby script that checks domain expiry dates using WHOIS and outputs results in a tab-separated format, sorted by expiry date.

## Requirements

- Ruby 3.0 or higher
- `whois` command-line tool

### Installing whois

**Ubuntu/Debian:**
```bash
sudo apt-get install whois
```

**macOS:**
```bash
brew install whois
```

**Other systems:**
The `whois` tool is typically pre-installed on most Unix-like systems.

## Usage

### From a file:
```bash
./domain_expiry_checker.rb domains.txt
```

### From stdin:
```bash
echo "google.com" | ./domain_expiry_checker.rb
cat domains.txt | ./domain_expiry_checker.rb
```

### Help:
```bash
./domain_expiry_checker.rb --help
```

## Input Format

Create a text file with one domain per line:
```
google.com
github.com
example.com
```

Lines starting with `#` are treated as comments and ignored.

See `domains.txt.example` for an example input file.

## Output Format

The script outputs a tab-separated list of domains and their expiry dates, sorted by expiry date (earliest first):

```
example.com     2024-08-13
google.com      2024-09-14
github.com      2025-10-09
```

Domains where the expiry date could not be determined will show `UNKNOWN` as the expiry date and appear at the end of the list.

## How It Works

1. Reads a list of domains from a file or stdin
2. For each domain, runs the `whois` command
3. Parses the WHOIS output to extract the expiry date using various common field names
4. Handles multiple date formats commonly used in WHOIS records
5. Sorts the results by expiry date
6. Outputs the results in tab-separated format

## Notes

- WHOIS queries can be rate-limited by registrars. Running the script on many domains may result in temporary blocks.
- Some domains may not return expiry information in their WHOIS records.
- The script handles various date formats, but some unusual formats may not be parsed correctly.

## License

MIT License - see LICENSE file for details.