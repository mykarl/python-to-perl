#!/usr/bin/perl -w

# Written by Michael Zhai September 2017

# TODO
# Reduce any unnessecary whitespace (i.e. sequential spaces)?
# Handle int(0.5+0.5)?
# Multiple brackets in control structures


my %variables = ();
my %lists = ();

while ($line = <>) {
   translateLine($line);
}

# Subroutine allows recursive calls
sub translateLine {
   # ensures line indentation is consistent with given code
   my $line = shift;
   $line =~ /(^\s*)/;
   my $indent = $1;
   $line =~ s/^\s*//;
   # skip if line is just newline (otherwise prints twice)
   if ($line =~ /^\n$/) {}
   else {
      print ($indent);
   }
   
   ##### PRE-LINE TRANSLATIONS #####
   # Deals with int() function
   $continue = 1;
   while ($continue == 1) {
      if ($line =~ /[^r]int\(([^\)]*)\)/) {
         my $argument = $1;
         # removes any decimals (if any)
         # will not always work if algebra is done inside argument
         $argument =~ s/\.\d+//;
         $line =~ s/([^r])int\([^\)]*\)/${1}${argument}/;
      }
      else {
         $continue = 0;
      }
   }
   # Prints on-line comments and removes them from translation
   if (!($line =~ /".*#.*"/)) {
      if ($line =~ /[^\s]+\s*(#.*)/) {
         print "${1}\n";
         print ($indent);
         $line =~ s/\s*#.*//;
      }
   }
   # Converts floor division
   if ($line =~ /\/\//) {
      $line =~ s/\/\//\//g;
   }
   # Converts sys.stdin
   if ($line =~ /sys.stdin(.?)/) {
      $line =~ s/sys.stdin([^\.]*)/\(<STDIN>\)$1/ if ($1 ne '.');
   }
   # Deals with len() on lists and strings
   # continue flag to remove all instances on the same line
   $continue = 1;
   while ($continue == 1) {
      if ($line =~ /len\(([^\)]*)\)/) {
         %duplicates = ();
         $expr = $1;
         $flag = 0;
         # check if any lists we need to prefix with @
         @arr = split('[^\w\@\d\"_]+', $expr);
         foreach $elem (@arr) {
            if (exists($lists{$elem}) && !exists($duplicates{$elem})) {
               $expr =~ s/(^|[^\d\w\@_])$elem([^\d\w\@_]|$)/${1}\@${elem}${2}/g;
               $duplicates{$elem}++;
               $flag = 1;
            }
         }
         # if list is passed into len()
         if ($flag == 1) {
            $line =~ s/len\([^\)]*\)/$expr/;
         }
         # if string is passed into len()
         else {
            $line =~ s/len\(/length\(/;
         }
      }
      else {
         $continue = 0;
      }
   }
   # Converts sorted()
   $continue = 1;
   while ($continue == 1) {
      if ($line =~ /sorted\s*\(.*\)/) {
         $line =~ s/sorted\s*\((.*)\)/sort \@$1/;
      }
      else {
         $continue = 0;
      }
   }
   
   
   
   ##### MAIN TRANSLATION #####
   # Deals with first #! line
   if ($line =~ /^#!/ && $. == 1) {
      print "#!/usr/bin/perl -w\n";
   } 
   
   # Blank & comment lines can be passed unchanged
   elsif ($line =~ /^\s*(#|$)/) {
      print $line;
   } 
   
   # Deals with new lines
   elsif ($line =~ /^\n/) {
      print $line;
   }
   
   # Import can be skipped
   elsif ($line =~ /^import/) {
   }
   
   # Handles break/continue statements
   elsif ($line =~ /break/) {
      print "last;\n";
   }
   elsif ($line =~ /continue/) {
      print "next;\n";
   }
   
   # Handles appending to lists
   elsif ($line =~ /([\w\@\d\"_]+)\.append\((.*)\)/) {
      my %duplicates = ();
      $listvar = $1;
      $args = $2;
         # checks for lists being passed in
         if ($args =~ /([\w\@\d\"_]+)?\[(.*)\]/) {
            $index = $1;
            $input = $2;
            # edge case with array element i.e. a[b]
            if (!(defined $index)) {
               $args =~ s/\[.*\]/\(${input}\)/;
            }
            # check if argument being passed is a variable (needs $ prefix)
            @arr = split('[^\w\@\d\"_]', $args);
            foreach $elem (@arr) {
               if (exists($variables{$elem}) && !exists($duplicates{$elem})) {
               $args =~ s/(^|[^\d\w\@_])$elem([^\d\w\@_]|$)/${1}\$${elem}${2}/g;
               $duplicates{$elem}++;
               }
            }
         }
         # otherwise, check if variable being passed in
         else {
            if (exists($variables{$args}) ) {
            $args =~ s/(^|[^\d\w\@_])$args([^\d\w\@_]|$)/${1}\$${args}${2}/g;
         }
      }
      print "push \@${listvar}, ${args};\n";
   }
   # Handles popping from lists
   elsif ($line =~ /([\w\@\d\"_]+)\.pop\((.*)\)/) {
      $listvar = $1;
      $args = $2;
      # no argument in pop()
      if ($args eq '') {
         print "pop \@${listvar};\n";
      }
      # argument given, check if argument is a variable (prefix with $)
      else {
         @arr = split('[^\w\@\d\"_]', $args);
         foreach $elem (@arr) {
         if (exists($variables{$elem})) {
            $args =~ s/(^|[^\d\w\@_])$elem([^\d\w\@_]|$)/${1}\$${elem}${2}/g;
         }
      }
         print "splice \@${listvar}, ${args}, 1;\n";
      }
   }
   
   # Handles sys.stdout.write()
   elsif ($line =~ /sys.stdout.write\s*\(("?.*"?)\)/) {
      $translated = printInPerl($1);
      $translated =~ s/, \"\\n\"//;
      print $translated;
   }
   
   # Handles sys.stdin.readline()
   elsif ($line =~ /sys.stdin.readline\s*\(\s*\)/) {
      $line =~ s/sys.stdin.readline\(\)/\<STDIN\>/;
      $type = "primitive";
      $translated = assignVariable($line, $type);
      print $translated;
   }
   
   # Handles while loops
   elsif ($line =~ /while.*:/) {
      $type = "while";
      controlStructureInPerl($line, $type, $indent);
   }
   
   # Handles if statements
   elsif ($line =~ /^if.*:/) {
      $type = "if";
      controlStructureInPerl($line, $type, $indent);
   }
   
   # Handles elif statements
   elsif ($line =~ /^elif.*:/) {
      $line =~ s/elif/elsif/;
      $type = "elsif";
      controlStructureInPerl($line, $type, $indent);
   }
   
   # Handles else statements
   elsif ($line =~ /^else:/) {
      $type = "else";
      controlStructureInPerl($line, $type, $indent);
   }
   
   # Handles for loops
   elsif ($line =~ /for .+ in .+:/) {
      $type = "for";
      controlStructureInPerl($line, $type, $indent);
   }
   
   # Python's print outputs a new-line character by default
   # so we need to add it explicitly to the Perl print statement
   # Handles printing of variables (not just strings)
   elsif ($line =~ /print\s*\(("?.*"?)\)/) {
      $translated = printInPerl($1);
      print $translated;
   } 
   
   # Handles sorted()
   elsif ($line =~ /([^\s]+)[\s]*=[\s]*sort[\s]*\@[^\s]+/) {
      chomp $line;
      $var = $1;
      $variables{$var}++;
      $lists{$var}++;
      print "\@${line};\n";
   }
   
   # Handles sys.stdin.readlines() assignment
   elsif ($line =~ /([^\s]+)[\s]*=[\s]*sys\.stdin\.readlines\s*\(\s*\)/) {
      $var = $1;
      $variables{$var}++;
      $lists{$var}++;
      print "push \@${var}, \$_ while \<STDIN\>;\n";
   }
   
   # Deals with variable assignments
   # Stores variables in a hash for identification later
   elsif ($line =~ /[^\s]+[\s]*=[\s]*(([^\s]+[\s]*)+)/) {
      $match = $1;
      if ($match =~ /^\[.*\]$/) {
         $type = "list";
      }
      else {
         $type = "primitive";
      }
      $translated = assignVariable($line, $type);
      print $translated;
   }
   
   
   # Lines we can't translate are turned into comments
   else {
      print "#$line\n";
   }
}

# Major function which translates if/while/for/etc loops
sub controlStructureInPerl {
      my %duplicates = ();
      
      my $line = shift;
      # type determines how we handle it
      my $type = shift;    
      # indent keeps track where the control structure ends
      my $indent = shift;  
      $line =~ s/\s+$//;
      $line =~ s/^\s+//;
      
      my @arr = split(':', $line);
      my $condition = shift @arr;
      my @arr2 = split('[^\w\@\d\"_]+', $condition);
      
      # for loops
      if ($type eq 'for') {
         $condition =~ s/\sin\s/ /;
         # replace for with foreach
         shift @arr2;
         $condition =~ s/^for/foreach/;
         # allocate the variable
         my $var = shift @arr2;
         $variables{$var}++;
         $condition =~ s/ ${var} / \$${var} /;
         # go past 'in'
         shift @arr2;
         # control parameter
         my $command = shift @arr2;
         if ($command eq 'range') {
            my $start;
            my $end;
            my @range_vars;
            my @find_vars;
            # if of form range(), determine start and stop
            $condition =~ /\((.*)\)$/;
            @range_vars = split (',', $1);
            # always need to check if arguments are variables and need $ prefix
            # if only one argument specified (stop parameter)
            if (@range_vars == 1) {
               $end = shift @range_vars;
               # checks for variables
               @find_vars = split ('[^\w\@\d\"_]+', $end);
               foreach $elem (@find_vars) {
                  if (exists($variables{$elem}) && !exists($duplicates{$elem})) {
                     $end =~ s/(^|[^\d\w\@_])$elem([^\d\w\@_]|$)/${1}\$${elem}${2}/g;
                     $duplicates{$elem}++;
                  }
               }
               # python is exclusive of the end parameter
               $end = "$end-1";
               $condition =~ s/range\(.*/\(0\.\.${end}\)/;
            }
            # else, start and stop are given
            else {
               $start = shift @range_vars;
               @find_vars = split ('[^\w\@\d\"_]+', $start);
               foreach $elem (@find_vars) {
                  if (exists($variables{$elem}) && !exists($duplicates{$elem})) {
                     $start =~ s/(^|[^\d\w\@_])$elem([^\d\w\@_]|$)/${1}\$${elem}${2}/g;
                     $duplicates{$elem}++;
                  }
               }
               # reset duplicate hash for end parameter
               %duplicates = ();
               
               $end = shift @range_vars;
               $end =~ s/^\s+//;
               @find_vars = split ('[^\w\@\d\"_]+', $end);
               foreach $elem (@find_vars) {
                  if (exists($variables{$elem}) && !exists($duplicates{$elem})) {
                     $end =~ s/(^|[^\d\w\@_])$elem([^\d\w\@_]|$)/${1}\$${elem}${2}/g;
                     $duplicates{$elem}++;
                  }
               }
               $end = "$end-1";
               $condition =~ s/range\(.*/\(${start}\.\.${end}\)/;
            }
         }
         # replace sys.stdin[.readlines()] with <STDIN>
         elsif ($command eq 'sys') {
            $func = shift @arr2;
            if ($func eq 'stdin') {
               $condition =~ s/sys.*/\(\<STDIN\>\)/;
            }
         }
         # if it is a list, prefix with @
         elsif (exists($lists{$command})) {
            $condition =~ s/([^\$])$command/${1}\(\@${command}\)/;
         }
         
         print "${condition} \{\n";
      }
        
      # handles while, if, elsif (same structure for all)
      elsif ($type eq 'while' || $type eq 'if' || $type eq 'elsif') {
         foreach $elem (@arr2) {
            if (exists($variables{$elem}) && !exists($duplicates{$elem})) {
               $condition =~ s/(^|[^\d\w\@_])$elem([^\d\w\@_]|$)/${1}\$${elem}${2}/g;
               $duplicates{$elem}++;
            }
         }
         $condition =~ s/$type /$type \(/;
         print "${condition}\) \{\n";
      }
      
      # handles else
      elsif ($type eq 'else') {
         print "$type \{\n";
      }
      
      # if the control stucture continues on the same line i.e. while(): print();
      # array will contain the lines after the : trigger
      if (@arr > 0) {
         my $statement = shift @arr;
         # split the continuing lines to be translated seperately
         my @arr3 = split('[;]', $statement);
         foreach my $elem (@arr3) {
            $elem =~ s/^\s+//;
            $elem =~ s/\s+$//;
            $elem = "\t$elem";
            # recursively translate each of the lines
            translateLine($elem);
         }
      }
      # otherwise, the control structure continues below (indented)
      # need to get the below lines until the indentation matches with the beginning line
      # tricky cases to handle with this method
      else {
         $nextLine = <>;
         $nextLine =~ /(^\s*)/;
         $nextIndent = $1;
         # while the indentation is not equal (i.e. still in the loop)
         while ($nextIndent ne $indent && $nextIndent ne '') {
            translateLine($nextLine);
            # do not parse next line if it is eof()
            last if eof();
            # otherwise, get next line
            $nextLine = <>;
            $nextLine =~ /(^\s*)/;
            $nextIndent = $1;
            $lineLength = length($nextLine);
         }
         # once indentation is equal, go back one line if not eof()
         # otherwise there is no more code to translate and we are done
         if (!eof()) {
            seek(ARGV, -$lineLength, 1);
         }
         # handles case where there is just one line until eof()
         elsif ($nextIndent eq $indent) { 
            seek(ARGV, -$lineLength, 1);
         }
      }
      
      print "${indent}\}\n";
}

# Function deals with all printing statements
sub printInPerl {
      my %duplicates = ();
      
      my $toPrint = shift;
      $toPrint =~ s/^\s+//;
      $toPrint =~ s/\s+$//;
      
      my @arr;
      # if the print function includes the % string operator
      if ($toPrint =~ /\"(.*)\"\s*\%\s*\(?([^\)]*)\)?/) {
         my $output = $1;
         my $sub = $2;
         # split the % (values)
         @arr = split('\s*,\s*', $sub);
         foreach $elem (@arr) {
            # check if any of the values are variables
            my @arr2 = split('[^\w\@\d\"_]', $elem);
            foreach my $temp (@arr2) {
               if (exists($variables{$temp}) && !exists($duplicates{$temp})) {
                  $sub =~ s/(^|[^\d\w\@_])$temp([^\d\w\@_]|$)/${1}\$${temp}${2}/g;
                  $duplicates{$temp}++;
               }
            }
         }
         # replace the %\w with the corresponding values
         @arr = split('\s*,\s*', $sub);
         while (@arr > 0) {
            my $var = shift @arr;
            $toPrint =~ s/\%\w\s/$var /;
         }
         $toPrint =~ s/\s*%\s*\(?[^\)]*\)?//;
      }
      # if printing a list, prefix with @
      elsif (exists($lists{$toPrint})) {
         $toPrint = "\@$toPrint";
      }
      else {
         @arr = split('[^\w\@\d\"_]', $toPrint);
         foreach $elem (@arr) {
            if (exists($variables{$elem}) && !exists($duplicates{$elem})) {
               $toPrint =~ s/(^|[^\d\w\@_])$elem([^\d\w\@_]|$)/${1}\$${elem}${2}/g;
               $duplicates{$elem}++;
            }
         }
      }
      
      my $string;
      # print nothing (and newline)
      if ($toPrint eq '') {
         $string = "print \"\\n\";\n";
      }
      # if print function includes (end = '.*')
      # change newline character to $end
      elsif ($toPrint =~ /,\s*end\s*=\s*'.*'/) {
         $toPrint =~ s/,\s*end\s*=\s*'(.*)'//;
         $string = "print ${toPrint}, \"$1\";\n"
      }
      # standard print with newline
      else {
         $string = "print ${toPrint}, \"\\n\";\n";
      }
      return $string;
}

# Function handles all variable assignments incl. lists
sub assignVariable {
      my %duplicates = ();
      
      my $line = shift;
      my $type = shift;
      chomp $line;
      $line =~ s/^\s+//;
      $line =~ s/\s+$//;
      my @arr = split('=', $line);
      
      # LHS is the variable\list name
      my $var = shift @arr;
      $var =~ s/\s//g;
      $variables{$var}++;
      $lists{$var}++ if $type eq 'list';
      
      # RHS is value of the variable
      my $expr = shift @arr;
      $expr =~ s/^\s+//;
      $expr =~ s/\s+$//;
      # check if any existing variables are used (need $)
      my @arr2 = split('[^\w\@\d\"_]+', $expr);
      foreach my $elem (@arr2) {
         if (exists($variables{$elem}) && !exists($duplicates{$elem})) {
            $expr =~ s/(^|[^\d\w\@_])$elem([^\d\w\@_]|$)/${1}\$${elem}${2}/g;
            $duplicates{$elem}++;
         }
      }
      my $string;
      if ($type eq 'primitive') {
         $string = "\$${var} = ${expr};\n";
      }
      elsif ($type eq 'list') {
         $expr =~ s/^\[/\(/;
         $expr =~ s/\]$/\)/;
         $string = "\@${var} = ${expr};\n";
      }
      return $string;
}
