#!/usr/bin/perl

#
# Copyright 2018 New Vector Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

use warnings;
use strict;
use File::Find;

my $usage = "Usage: $0 CONFIG_FILE ROOT_PATH...\n";

my $config_file = shift or die $usage;
my $root = shift or die $usage;

# Read configuration file

open my $CONFIG, '<', $config_file or die "Config file not found";

my %config;
my %last_found_occurrence_file;

while(<$CONFIG>) {
    chomp;

    # Skip empty lines
    next if(/^$/);

    # Skip comment
    next if(/^#/);

    my @array = split("/===/");

    if($#array > 1) {
        $config{$array[0]} = -1 * $array[1];
    } else {
        $config{$array[0]} = 0;
    }
}

close $CONFIG;

while ($root) {
    find( \&analyseFile, $root );

    $root = shift;
}

my $error = 0;

foreach (keys(%config)) {
    if($config{$_} > 0) {
        print "Error: '" . $_ . "' detected " . $config{$_} . " time(s), last in file '" . $last_found_occurrence_file{$_} . "'.\n";
        $error++;
    }
}

if($error > 0) {
    print STDERR $error . " forbidden pattern(s) detected\n";
    exit 1;
} else {
    print STDERR "All clear, commit allowed!\n";
    exit 0;
}

# Subs

sub analyseFile {
    my $file = $_;

    open my $INPUT, '<', $file or do {
        warn qq|WARNING: Could not open $File::Find::name\n|;
        return;
    };

    while ( <$INPUT> ) {
        my $line = $_;

        foreach (keys(%config)) {
            if ($line =~ /$_/) {
                $config{$_}++;
                $last_found_occurrence_file{$_} = $File::Find::name;
            }
        }
    }

    close $INPUT;
}
