#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use File::Find;
use open qw(:std :utf8);

my $content_dir = 'content/post';
my $total_files = 0;
my $modified_files = 0;

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
    
    # HTML to Markdown conversion
    $content = convert_html_to_markdown($content);
    
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

sub convert_html_to_markdown {
    my $text = shift;
    
    # Split into front matter and body
    my ($front_matter, $body);
    if ($text =~ /^(---\n.*?\n---\n)(.*)$/s) {
        $front_matter = $1;
        $body = $2;
    } else {
        return $text;
    }
    
    # Convert HTML tags to Markdown (only in body)
    
    # Convert <h1> to # (heading level 1)
    $body =~ s{<h1>(.*?)</h1>}{# $1}gis;
    
    # Convert <h2> to ## (heading level 2)
    $body =~ s{<h2>(.*?)</h2>}{## $1}gis;
    
    # Convert <h3> to ### (heading level 3)
    $body =~ s{<h3>(.*?)</h3>}{### $1}gis;
    
    # Convert <h4> to #### (heading level 4)
    $body =~ s{<h4>(.*?)</h4>}{#### $1}gis;
    
    # Convert <h5> to ##### (heading level 5)
    $body =~ s{<h5>(.*?)</h5>}{##### $1}gis;
    
    # Convert <h6> to ###### (heading level 6)
    $body =~ s{<h6>(.*?)</h6>}{###### $1}gis;
    
    # Convert <strong> or <b> to **text**
    $body =~ s{<strong>(.*?)</strong>}{**$1**}gis;
    $body =~ s{<b>(.*?)</b>}{**$1**}gis;
    
    # Convert <em> or <i> to *text*
    $body =~ s{<em>(.*?)</em>}{*$1*}gis;
    $body =~ s{<i>(.*?)</i>}{*$1*}gis;
    
    # Convert <br> or <br/> or <br /> to newline
    $body =~ s{<br\s*/?\s*>}{\n}gis;
    
    # Convert <p>text</p> - handle inline and block separately
    # First, handle simple cases where <p> and </p> are on separate lines
    $body =~ s{<p>\s*\n}{\n}gis;
    $body =~ s{\n\s*</p>}{\n\n}gis;
    
    # Then handle inline <p>text</p> - add space after
    $body =~ s{<p>(.*?)</p>\s*}{$1\n\n}gis;
    
    # Convert unordered lists
    # First handle multi-line <ul>...</ul>
    $body =~ s{<ul>\s*\n?}{<UL_START>}gis;
    $body =~ s{\n?\s*</ul>}{<UL_END>}gis;
    
    # Convert <li> items
    $body =~ s{<li>(.*?)</li>}{- $1\n}gis;
    
    # Clean up list markers
    $body =~ s{<UL_START>}{\n}gis;
    $body =~ s{<UL_END>}{\n}gis;
    
    # Convert ordered lists
    $body =~ s{<ol>\s*\n?}{<OL_START>}gis;
    $body =~ s{\n?\s*</ol>}{<OL_END>}gis;
    
    # For ordered lists, we need to number them
    my $ol_counter = 1;
    $body =~ s{<OL_START>(.*?)<OL_END>}{
        my $list_content = $1;
        $ol_counter = 1;
        $list_content =~ s{<li>(.*?)</li>}{($ol_counter++) . ". $1\n"}gies;
        "\n" . $list_content . "\n";
    }gies;
    
    # Convert links <a href="url">text</a> to [text](url)
    $body =~ s{<a\s+href=["']([^"']+)["']>([^<]*)</a>}{[$2]($1)}gis;
    
    # Remove any remaining standalone opening/closing tags
    $body =~ s{^\s*<p>\s*$}{}gim;
    $body =~ s{^\s*</p>\s*$}{}gim;
    
    # Clean up excessive newlines (more than 2 consecutive)
    $body =~ s{\n{3,}}{\n\n}gs;
    
    # Trim trailing whitespace from lines
    $body =~ s{[ \t]+$}{}gm;
    
    # Trim excessive trailing whitespace at end of body
    $body =~ s{\s+$}{\n}s;
    
    # Combine front matter and body
    return $front_matter . $body;
}

sub convert_fullwidth_to_halfwidth {
    my $text = shift;
    
    # Convert full-width alphanumeric to half-width
    # Full-width 0-9: ０-９ (U+FF10 - U+FF19)
    # Full-width A-Z: Ａ-Ｚ (U+FF21 - U+FF3A)
    # Full-width a-z: ａ-ｚ (U+FF41 - U+FF5A)
    
    $text =~ s{([０-９Ａ-Ｚａ-ｚ])}{
        my $char = $1;
        my $code = ord($char);
        # Full-width to half-width conversion
        # Offset is 0xFEE0
        chr($code - 0xFEE0);
    }ge;
    
    return $text;
}
