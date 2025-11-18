#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use File::Find;
use File::Temp qw(tempfile);
use open qw(:std :utf8);

my $content_dir = 'content/post';
my $total_files = 0;
my $modified_files = 0;

# Check if html2markdown is available
my $html2markdown = `which html2markdown 2>/dev/null` || "$ENV{HOME}/go/bin/html2markdown";
chomp $html2markdown;
unless (-x $html2markdown) {
    die "Error: html2markdown not found. Please install it:\n" .
        "  go install github.com/JohannesKaufmann/html-to-markdown/v2/cli/html2markdown\@latest\n";
}

# Find all markdown files
my @files;
find(sub {
    push @files, $File::Find::name if -f && /\.md$/;
}, $content_dir);

# Process each file
foreach my $file (@files) {
    $total_files++;
    
    # Read file
    open my $fh, '<:encoding(UTF-8)', $file or die "Cannot open $file: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    
    my $original = $content;
    
    # HTML to Markdown conversion using html2markdown tool
    $content = convert_html_to_markdown_with_tool($content);
    
    # Full-width to half-width alphanumeric conversion
    $content = convert_fullwidth_to_halfwidth($content);
    
    # Save if modified
    if ($content ne $original) {
        open my $out, '>:encoding(UTF-8)', $file or die "Cannot write to $file: $!";
        print $out $content;
        close $out;
        
        $modified_files++;
        print "Modified: $file\n";
    }
}

print "\nTotal files processed: $total_files\n";
print "Modified files: $modified_files\n";

sub convert_html_to_markdown_with_tool {
    my $text = shift;
    
    # Split into front matter and body
    my ($front_matter, $body);
    if ($text =~ /^(---\n.*?\n---\n)(.*)$/s) {
        $front_matter = $1;
        $body = $2;
    } else {
        return $text;
    }
    
    # Step 1: Extract and protect code blocks
    my @code_blocks;
    my $code_block_counter = 0;
    
    # Match code blocks (``` fenced code blocks)
    $body =~ s{(```[^\n]*\n.*?\n```\n)}
              {
                  my $code = $1;
                  push @code_blocks, $code;
                  my $idx = $code_block_counter++;
                  "\n\nCODEBLOCKPLACEHOLDER${idx}ENDPLACEHOLDER\n\n";
              }gse;
    
    # Step 2: Convert HTML to Markdown using html2markdown tool
    # Only convert if there's actual HTML content
    if ($body =~ /<[^>]+>/) {
        # Create temporary file for html2markdown input
        my ($in_fh, $in_filename) = tempfile(SUFFIX => '.html', UNLINK => 1);
        binmode($in_fh, ':encoding(UTF-8)');
        print $in_fh $body;
        close $in_fh;
        
        # Run html2markdown
        my $converted = `$html2markdown --input "$in_filename" 2>/dev/null`;
        if ($? == 0 && $converted) {
            $body = $converted;
        }
    }
    
    # Step 3: Clean up excessive newlines and trailing whitespace
    $body =~ s{\n{3,}}{\n\n}gs;
    $body =~ s{[ \t]+$}{}gm;
    $body =~ s{\s+$}{\n}s;
    
    # Step 4: Restore code blocks
    for (my $i = 0; $i < @code_blocks; $i++) {
        $body =~ s{CODEBLOCKPLACEHOLDER${i}ENDPLACEHOLDER}{$code_blocks[$i]}g;
    }
    
    # Combine front matter and body
    return $front_matter . $body;
}

sub convert_fullwidth_to_halfwidth {
    my $text = shift;
    
    # Split into front matter and body
    my ($front_matter, $body);
    if ($text =~ /^(---\n.*?\n---\n)(.*)$/s) {
        $front_matter = $1;
        $body = $2;
    } else {
        # No front matter, process entire text
        $front_matter = '';
        $body = $text;
    }
    
    # Step 1: Extract and protect code blocks
    my @code_blocks;
    my $code_block_counter = 0;
    
    # Match code blocks (``` fenced code blocks)
    $body =~ s{(```[^\n]*\n.*?\n```\n)}
              {
                  my $code = $1;
                  push @code_blocks, $code;
                  my $idx = $code_block_counter++;
                  "\n\nCODEBLOCKPLACEHOLDER${idx}ENDPLACEHOLDER\n\n";
              }gse;
    
    # Step 2: Convert full-width alphanumeric to half-width (only outside code blocks)
    # Full-width 0-9: ０-９ (U+FF10 - U+FF19)
    # Full-width A-Z: Ａ-Ｚ (U+FF21 - U+FF3A)
    # Full-width a-z: ａ-ｚ (U+FF41 - U+FF5A)
    
    $body =~ s{([０-９Ａ-Ｚａ-ｚ])}{
        my $char = $1;
        my $code = ord($char);
        # Full-width to half-width conversion
        # Offset is 0xFEE0
        chr($code - 0xFEE0);
    }ge;
    
    # Step 3: Restore code blocks
    for (my $i = 0; $i < @code_blocks; $i++) {
        $body =~ s{CODEBLOCKPLACEHOLDER${i}ENDPLACEHOLDER}{$code_blocks[$i]}g;
    }
    
    return $front_matter . $body;
}
