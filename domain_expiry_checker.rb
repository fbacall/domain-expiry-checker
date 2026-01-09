#!/usr/bin/env ruby
# frozen_string_literal: true

require 'date'
require 'open3'

# DomainExpiryChecker - A tool to check domain expiry dates via WHOIS
class DomainExpiryChecker
  # Common patterns for expiry date fields in WHOIS output
  EXPIRY_PATTERNS = [
    /Registry Expiry Date:\s*(.+)/i,
    /Registrar Registration Expiration Date:\s*(.+)/i,
    /Expiration Date:\s*(.+)/i,
    /Expiry Date:\s*(.+)/i,
    /Expiry date:\s*(.+)/i,
    /Expires:\s*(.+)/i,
    /Expire Date:\s*(.+)/i,
    /paid-till:\s*(.+)/i,
    /renewal date:\s*(.+)/i,
    /expire:\s*(.+)/i
  ].freeze

  def initialize(domains)
    @domains = domains
    @results = []
  end

  def run
    @domains.each do |domain|
      domain = domain.strip
      next if domain.empty? || domain.start_with?('#')

      expiry_date = fetch_expiry_date(domain)
      @results << { domain: domain, expiry_date: expiry_date }
    end

    output_results
  end

  private

  def fetch_expiry_date(domain)
    stdout, stderr, status = Open3.capture3('whois', domain)

    unless status.success?
      warn "Warning: Failed to query WHOIS for #{domain}: #{stderr}"
      return nil
    end

    parse_expiry_date(stdout)
  rescue StandardError => e
    warn "Error querying #{domain}: #{e.message}"
    nil
  end

  def parse_expiry_date(whois_output)
    EXPIRY_PATTERNS.each do |pattern|
      match = whois_output.match(pattern)
      if match
        date_string = match[1].strip
        return parse_date_string(date_string)
      end
    end

    nil
  end

  def parse_date_string(date_string)
    # Remove common suffixes and clean up the string
    date_string = date_string.split(/\s+\(/).first # Remove timezone in parentheses
    date_string = date_string.gsub(/\s+[A-Z]{3,4}\s*$/, '') # Remove timezone abbreviations at end

    # Try various date formats
    formats = [
      '%Y-%m-%dT%H:%M:%S%z',     # 2024-01-15T10:30:00Z
      '%Y-%m-%dT%H:%M:%SZ',       # 2024-01-15T10:30:00Z
      '%Y-%m-%d %H:%M:%S',        # 2024-01-15 10:30:00
      '%Y-%m-%d',                 # 2024-01-15
      '%d-%b-%Y',                 # 15-Jan-2024
      '%d/%m/%Y',                 # 15/01/2024
      '%d.%m.%Y',                 # 15.01.2024
      '%Y.%m.%d',                 # 2024.01.15
      '%d-%m-%Y',                 # 15-01-2024
      '%Y/%m/%d',                 # 2024/01/15
      '%B %d %Y',                 # January 15 2024
      '%d %B %Y',                 # 15 January 2024
      '%b %d %Y',                 # Jan 15 2024
      '%d %b %Y'                  # 15 Jan 2024
    ]

    formats.each do |format|
      begin
        return Date.strptime(date_string, format)
      rescue ArgumentError, Date::Error
        next
      end
    end

    # If all else fails, try DateTime.parse (more lenient)
    begin
      DateTime.parse(date_string).to_date
    rescue ArgumentError, Date::Error
      nil
    end
  end

  def output_results
    # Sort by expiry date (nil values at the end)
    sorted_results = @results.sort_by do |result|
      result[:expiry_date] ? result[:expiry_date] : Date.new(9999, 12, 31)
    end

    # Output tab-separated results
    sorted_results.each do |result|
      domain = result[:domain]
      expiry_date = result[:expiry_date] ? result[:expiry_date].strftime('%Y-%m-%d') : 'UNKNOWN'
      puts "#{domain}\t#{expiry_date}"
    end
  end
end

# Main execution
if __FILE__ == $PROGRAM_NAME
  domains = []

  if ARGV.empty?
    # Read from stdin
    domains = $stdin.readlines.map(&:strip)
  elsif ARGV[0] == '-h' || ARGV[0] == '--help'
    puts "Usage: #{$PROGRAM_NAME} [domains_file]"
    puts
    puts "Checks domain expiry dates using WHOIS and outputs results in tab-separated format."
    puts
    puts "Arguments:"
    puts "  domains_file    File containing list of domains (one per line)"
    puts "                  If not provided, reads from stdin"
    puts
    puts "Output:"
    puts "  Tab-separated list of domains and expiry dates, sorted by expiry date"
    puts
    puts "Examples:"
    puts "  #{$PROGRAM_NAME} domains.txt"
    puts "  echo 'google.com' | #{$PROGRAM_NAME}"
    puts "  cat domains.txt | #{$PROGRAM_NAME}"
    exit 0
  else
    # Read from file
    filename = ARGV[0]
    unless File.exist?(filename)
      warn "Error: File '#{filename}' not found"
      exit 1
    end
    domains = File.readlines(filename).map(&:strip)
  end

  if domains.empty?
    warn "Error: No domains provided"
    exit 1
  end

  checker = DomainExpiryChecker.new(domains)
  checker.run
end
