#***********************************************************************
#
# Name:   mobile_check_css.pm
#
# $Revision: 167 $
# $URL: svn://10.36.20.203/Mobile_Check/Tools/mobile_check_css.pm $
# $Date: 2016-12-21 08:15:44 -0500 (Wed, 21 Dec 2016) $
#
# Description:
#
#   This file contains routines that parse CSS files and check for
# a number of mobile optimization checkpoints.
#
# Public functions:
#     Set_Mobile_Check_CSS_Language
#     Set_Mobile_Check_CSS_Debug
#     Set_Mobile_Check_CSS_Testcase_Data
#     Set_Mobile_Check_CSS_Test_Profile
#     Mobile_Check_CSS
#
# Terms and Conditions of Use
#
# Unless otherwise noted, this computer program source code
# is covered under Crown Copyright, Government of Canada, and is
# distributed under the MIT License.
#
# MIT License
#
# Copyright (c) 2011 Government of Canada
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
#***********************************************************************

package mobile_check_css;

use strict;
use File::Basename;

#
# Use WPSS_Tool program modules
#
use mobile_testcases;
use tqa_result_object;

#***********************************************************************
#
# Export package globals
#
#***********************************************************************
BEGIN {
    use Exporter   ();
    use vars qw($VERSION @ISA @EXPORT);

    @ISA     = qw(Exporter);
    @EXPORT  = qw(Set_Mobile_Check_CSS_Language
                  Set_Mobile_Check_CSS_Debug
                  Set_Mobile_Check_CSS_Testcase_Data
                  Set_Mobile_Check_CSS_Test_Profile
                  Mobile_Check_CSS
                  );
    $VERSION = "1.0";
}

#***********************************************************************
#
# File Local variable declarations
#
#***********************************************************************

my ($debug) = 0;

my (%testcase_data, %mobile_check_profile_map, $current_mobile_check_profile);
my ($results_list_addr, $current_url);
my ($max_comment_percentage, $max_whitespace_percentage);

#
# Status values
#
my ($check_pass)       = 0;
my ($check_fail)       = 1;

#
# String table for error strings.
#
my %string_table_en = (
    "Comment percentage",            "Comment percentage",
    "exceeds maximum acceptable value", "exceeds maximum acceptable value",
    "Whitespace percentage",         "Whitespace percentage",
    "\@import found in CSS",         "\@import found in CSS",
    );

my %string_table_fr = (
    "Comment percentage",            "Pourcentage de commentaires de code",
    "exceeds maximum acceptable value", "d�passe la valeur maximale acceptable",
    "Whitespace percentage",         "Pourcentage de caract�res d'espacement",
    "\@import found in CSS",         "\@import trouv� en CSS",
    );

#
# Default messages to English
#
my ($string_table) = \%string_table_en;

#***********************************************************************
#
# Name: Set_Mobile_Check_CSS_Debug
#
# Parameters: this_debug - debug flag
#
# Description:
#
#   This function sets the package global debug flag.
#
#***********************************************************************
sub Set_Mobile_Check_CSS_Debug {
    my ($this_debug) = @_;

    #
    # Copy debug value to global variable
    #
    $debug = $this_debug;
}

#**********************************************************************
#
# Name: Set_Mobile_Check_CSS_Language
#
# Parameters: language
#
# Description:
#
#   This function sets the language of error messages generated
# by this module.
#
#***********************************************************************
sub Set_Mobile_Check_CSS_Language {
    my ($language) = @_;

    #
    # Check for French language
    #
    if ( $language =~ /^fr/i ) {
        $string_table = \%string_table_fr;
    }
    else {
        #
        # Default language is English
        #
        $string_table = \%string_table_en;
    }
    
    #
    # Set language in supporting modules
    #
    Mobile_Testcase_Language($language);
}

#***********************************************************************
#
# Name: Set_Mobile_Check_CSS_Testcase_Data
#
# Parameters: profile - testcase profile
#             testcase - testcase identifier
#             data - string of data
#
# Description:
#
#   This function copies the passed data into a hash table
# for the specified testcase identifier.
#
#***********************************************************************
sub Set_Mobile_Check_CSS_Testcase_Data {
    my ($profile, $testcase, $data) = @_;

    my ($variable, $value);
    
    #
    # Get testcase specific data
    #
    if ( $testcase eq "MINIFY" ) {
        #
        # Get markup type and value
        #
        ($variable, $value) = split(/\s+/, $data);

        #
        # Save maximum character counts
        #
        if ( defined($value) && ($variable eq "COMMENT") ) {
            $max_comment_percentage = $value;
        }
        elsif ( defined($value) && ($variable eq "WHITESPACE") ) {
            $max_whitespace_percentage = $value;
        }
    }
    else {
        #
        # Copy the data into the table
        #
        $testcase_data{$testcase} = $data;
    }
}

#***********************************************************************
#
# Name: Set_Mobile_Check_CSS_Test_Profile
#
# Parameters: profile - profile name
#             mobile_checks - hash table of testcase name
#
# Description:
#
#   This function copies the passed table to unit global variables.
# The hash table is indexed by testcase name.
#
#***********************************************************************
sub Set_Mobile_Check_CSS_Test_Profile {
    my ($profile, $mobile_checks ) = @_;

    my (%local_mobile_checks);

    #
    # Make a local copy of the hash table as we will be storing the address
    # of the hash.
    #
    print "Set_Mobile_Check_CSS_Test_Profile, profile = $profile\n" if $debug;
    %local_mobile_checks = %$mobile_checks;
    $mobile_check_profile_map{$profile} = \%local_mobile_checks;
}

#***********************************************************************
#
# Name: Initialize_Test_Results
#
# Parameters: profile - Mobile check test profile
#             local_results_list_addr - address of results list.
#
# Description:
#
#   This function initializes the test case results table.
#
#***********************************************************************
sub Initialize_Test_Results {
    my ($profile, $local_results_list_addr) = @_;

    #
    # Set current hash tables
    #
    $current_mobile_check_profile = $mobile_check_profile_map{$profile};
    $results_list_addr = $local_results_list_addr;

}

#**********************************************************************
#
# Name: String_Value
#
# Parameters: key - string table key
#
# Description:
#
#   This function returns the value in the string table for the
# specified key.  If there is no entry in the table an error string
# is returned.
#
#**********************************************************************
sub String_Value {
    my ($key) = @_;

    #
    # Do we have a string table entry for this key ?
    #
    if ( defined($$string_table{$key}) ) {
        #
        # return value
        #
        return ($$string_table{$key});
    }
    else {
        #
        # No string table entry, either we are missing a string or
        # we have a typo in the key name.
        #
        return ("*** No string for $key ***");
    }
}

#***********************************************************************
#
# Name: Print_Error
#
# Parameters: line - line number
#             column - column number
#             text - text from tag
#             error_string - error string
#
# Description:
#
#   This function prints error messages if debugging is enabled..
#
#***********************************************************************
sub Print_Error {
    my ( $line, $column, $text, $error_string ) = @_;

    #
    # Print error message if we are in debug mode
    #
    if ( $debug ) {
        print "$error_string\n";
    }
}

#***********************************************************************
#
# Name: Record_Result
#
# Parameters: testcase - testcase identifier
#             line - line number
#             column - column number
#             text - text from tag
#             error_string - error string
#
# Description:
#
#   This function records the testcase result.
#
#***********************************************************************
sub Record_Result {
    my ( $testcase, $line, $column, $text, $error_string ) = @_;

    my ($result_object);

    #
    # Is this testcase included in the profile
    #
    if ( defined($testcase) && defined($$current_mobile_check_profile{$testcase}) ) {
        #
        # Create result object and save details
        #
        $result_object = tqa_result_object->new($testcase, $check_fail,
                                                Mobile_Testcase_Description($testcase),
                                                $line, $column, $text,
                                                $error_string, $current_url);
        push (@$results_list_addr, $result_object);

        #
        # Print error string to stdout
        #
        Print_Error($line, $column, $text, "$testcase : $error_string");
    }
}

#***********************************************************************
#
# Name: Check_CSS_Import
#
# Parameters: this_url - a URL
#             content - content pointer
#
# Description:
#
#   This function checks for @import rules in the CSS content.
#
#***********************************************************************
sub Check_CSS_Import {
    my ($this_url, $content) = @_;
    
    my (@lines, $line, $line_no);
    
    #
    # Check for @import in the content
    #
    print "Check_CSS_Import\n" if $debug;
    @lines = split(/\n/, $$content);
    $line_no = 0;
    foreach $line (@lines) {
        $line_no++;
        
        if ( $line =~ /\@import\s+/ ) {
            Record_Result("CSS_LINK", $line_no, -1, $line,
                          String_Value("\@import found in CSS"));
        }
    }
}

#***********************************************************************
#
# Name: Mobile_Check_CSS
#
# Parameters: this_url - a URL
#             language - URL language
#             profile - testcase profile
#             mime_type - mime type of content
#             resp - HTTP::Response object
#             content - content pointer
#
# Description:
#
#   This function runs a number of mobile QA checks the content.
#
#***********************************************************************
sub Mobile_Check_CSS {
    my ($this_url, $language, $profile, $mime_type, $resp, $content) = @_;

    my (@tqa_results_list, $result_object, $css_content, $css_char_count);
    my ($non_comment_char_count, $non_whitespace_count, $percent);
    my ($css_no_comment_content);

    #
    # Check for mobile optimization
    #
    print "Mobile_Check_CSS\n" if $debug;

    #
    # Initialize the test case pass/fail table.
    #
    Initialize_Test_Results($profile, \@tqa_results_list);
    $current_url = $this_url;
    
    #
    # Remove any comments from the CSS content
    #
    $css_content = $$content;
    $css_char_count = length($css_content);
    $css_content =~ s/\/\*[^*]*\*+([^\/*][^*]*\*+)*\///g;
    $css_no_comment_content = $css_content;

    #
    # Get the number of characters in the CSS content after
    # comments have been removed
    #
    $non_comment_char_count = length($css_content);
    
    #
    # Remove all the whitespace characters to get the count of non-whitespace
    #
    $css_content =~ s/\s*//g;
    $non_whitespace_count = length($css_content);
    
    #
    # Check to see if the content appears to be minified by checking the
    # percentage of comments and whitespace in the content.
    #
    print "Original size = $css_char_count, comments removed $non_comment_char_count, non-whitespace $non_whitespace_count\n" if $debug;
    if ( $css_char_count > 500 ) {
        #
        # Do comments exceed maximum percentage ?
        #
        $percent = int((($css_char_count - $non_comment_char_count) / $css_char_count) * 100);
        if ( defined($max_comment_percentage) && ($percent > $max_comment_percentage) ) {
            print "Greater than $max_comment_percentage % of content is comments\n" if $debug;
            Record_Result("MINIFY", -1, -1, "",
                          String_Value("Comment percentage") .
                          " $percent % " .
                          String_Value("exceeds maximum acceptable value") .
                          " $max_comment_percentage %");
        }
        else {
            #
            # Does whitespace exceed maximum percentage ?
            #
            $percent = int((($non_comment_char_count - $non_whitespace_count) / $non_comment_char_count) * 100);
            if ( defined($max_whitespace_percentage) && ($percent > $max_whitespace_percentage) ) {
                print "Greater than $max_whitespace_percentage % of non-comment content is whitespace\n" if $debug;
                Record_Result("MINIFY", -1, -1, "",
                              String_Value("Whitespace percentage") .
                              " $percent % " .
                              String_Value("exceeds maximum acceptable value") .
                              " $max_whitespace_percentage %");
            }
        }
    }
    
    #
    # Check for possible @import statements in the CSS content
    #
    Check_CSS_Import($this_url, \$css_no_comment_content);

    #
    # Return list of results
    #
    return(@tqa_results_list);
}

#***********************************************************************
#
# Mainline
#
#***********************************************************************

#
# Return true to indicate we loaded successfully
#
return 1;

