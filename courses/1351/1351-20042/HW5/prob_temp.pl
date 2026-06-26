#!/usr/bin/perl -w

## This script is based on code originally written by Colin Black, formerly of 
## Lawerence Technoligical University
## Edits to expand functionality and usability made by
## Mark Schmitt, Detroit Country Day School
## 
## This script is current as of 7/20/2002

## Major differences from original script:
##  Added support for Matching questions
##  Added support for directory hierachies
##  Patched bug in MC questions that required All or None of the Above
##  Patched bug in MC questions that printed correct answer twice
##  Picture support has been added, but remains an undocumented feature
##      To include an image in the question text, type PICTURE(name)

## Future Improvements:
##  Bad-Case Trapping (for selection of random variables)
##  ??

## Please direct all comments and suggestions to mschmitt@dcds.edu


use strict;
use CGI;
use CGI::Pretty;
use CGI::Carp qw(fatalsToBrowser);

my $q = new CGI;

## any data that must be changed for local use is marked with a commented line 
## containing the words COURSE SPECIFIC DATA
## searching for that phrase will find all spaces that need attention
##

## COURSE SPECIFIC DATA
## $SCRIPT_NAME should be set to the filename of this script.  It may be unique
## for each class that maintains this script.

my $SCRIPT_NAME = 'Template.pl';


# A few constants for file location and such

# Edit by Mark Schmitt
# STORE_DIRECTORY changed to START_DIRECTORY to facilitate directory structure
# START_DIRECTORY should have the pathname to the main problem directory for the course
# sub directories are dealt with later

## COURSE SPECIFIC DATA
## $START_DIRECTORY is the base directory for storing problems.  Each course
## should have its own $START_DIRECTORY

my $START_DIRECTORY = '/home/httpd/webwork/courses/Problems/Chemistry';
my $STORE_DIRECTORY = '';
#

my $NUMBER = qr(^(-|)\d*?(\.|)\d+$);
my $ILLEGAL = qr/!|\@|#|\$|%|\^|&|\*|\(|\)|\r|\t|\n|\+|\-|\/|\\|\||'|"|;|:|<|,|>|\.|\?|~|`| /;

# Start Header Processing
  # Any header processing, as far as identity checking goes here
  print $q->header();
# End Header Processing

my @tfAns = ('True', 'False');
# Edit by Mark Schmitt
# added the matching question-type
my @qtype = ('FITB', 'TF', 'MC','Match');
my %qtypes = ('TF'=>'True/False', 'FITB'=>'Fill-in-the-Blank', 'MC'=>'Multiple Choice','Match'=>'Matching');

# Edit by Mark Schmitt
# qDirectory added to faciliate directory structure. 
# These variables must be editted to to the correct final directory name

## COURSE SPECIFIC DATA
## @qDirectory should contain the actual name of the subdirectories under $START_DIRECTORY where problems are stored
## %qDirectories should contain aliases that appear in the drop-down menu within the script

my @qDirectory = ('Dimension','Atoms','Nomenclature','Ions','Equations','Stoichiometry');
my %qDirectories = ('Dimension'=>'Dimensional Analysis',
            'Atoms'=>'Atomic Structure',
            'Nomenclature'=>'Nomenclature',
            'Ions'=>'Ionic Compounds',
            'Equations'=>'Equations',
            'Stoichiometry'=>'Stoichiometry');
#

sub checkAndWriteQuestion
{
  my %errorList;
  my $errorFlag;
  my (@includes, @comments, @variables, @intVariables);            # Standard variables
  my ($qType);                                                     # more
  my (@mcNormal, @mcAddOns, @mcCorrect, @mcquestions, @mcrandom);  # MC variables
  my (@tfquestions, @tfAns, $tfchoose);                            # TF variables
  my (@matchquestions, @matchAns, $matchchoose);
  my (@fitbLines, $questionFITB);                                  # FITB variables
  my %validVariableNames;
  my $q = new CGI;

  # Check filename

  # Edit by Mark Schmitt
  # Added test for final directory name
  my $final_Directory = $q->param('qDirectory');
  my $fileName = $q->param('qName');
  if(not $final_Directory)
  {
    push(@{$errorList{'Name'}}, 'No Directory Selected');
    $errorFlag = 1;
  }
  else
  {
  # Edit by Mark Schmitt
  # Define STORE_DIRECTORY using START_DIRECTORY and the selected directory
  $STORE_DIRECTORY = $START_DIRECTORY."/".$final_Directory;
  if(not $fileName)                          # Did they fill in the filename?
  {
    push(@{$errorList{'Name'}}, 'No Question Name Entered');
    $errorFlag = 1;
  }
  else
  {
    $fileName =~ s/\.pg$//;                    # Did they add the .pg extension?
  }
  }

  # Critical point, quit if errors were detected
  if($errorFlag){return ($errorFlag, %errorList);}

  if(($fileName =~ $ILLEGAL) or ($fileName =~ m/(^_)|(_$)/))
  {
    push(@{$errorList{'Name'}}, "Question has illegal characters in its name($fileName)");
    $errorFlag = 1;
  }
  elsif(-e "$STORE_DIRECTORY/$fileName.pg")
  {
    push(@{$errorList{'Name'}}, 'Question Name already in use');
    $errorFlag = 1;
    $errorList{'flagNameAlreadyExists'} = 'true';
  }

  # Define/Verify includes
  @includes = ('"PG.pl"',
               '"PGbasicmacros.pl"',
               '"PGchoicemacros.pl"',
               '"PGanswermacros.pl"',
               '"PGauxiliaryFunctions.pl"');
  my @newmacros = $q->param('includes');
  @newmacros = () unless (@newmacros);
  foreach(@newmacros)
  {
    if($_ =~ m/PG(complex|diffeq|matrix|numerical|polynomial|statistics)macros.pl/)
    {
      push(@includes, qq/"$_"/);
    }
    else
    {
      push(@{$errorList{'Includes'}}, "$_ is unrecognized by the system");
      $errorFlag = 1;
    }  
  }
  undef @newmacros; # Done with it so empty
  
  # Check Comments
  my $commentsTemp = $q->param('comments');
  if(defined $commentsTemp)
  {
    @comments = split(/\x0D\x0A|\n/, $commentsTemp);
    foreach(@comments)
    {
      if($_ !~ m/^#/)
      {
        $_ = "#$_";
      }
    }
    undef $commentsTemp; # Done with it so empty
  }
  
  # Check variables
  my $varTableCount = $q->param('vartable');
  for(my $i = 0; $i < $varTableCount; $i++)
  {
    my ($name, $min, $max, $inc) = ($q->param("gvName$i"), $q->param("gvMin$i"), $q->param("gvMax$i"), $q->param("gvInc$i"));
    my $nonzero = $q->param("gvNonzero$i");
# Edit by Mark Schmitt
# additional variables needed for this section
    my ($badMin,$badMax,$badInc);
    if($name and $name =~ m/^\$(.+)/){$name = $1;}  # Remove '$' from start of variable, if it exists
# Edit by Mark Schmitt
# Check if $min, $max, and $inc each contain at most one previously defined variable    
    if ($min and $min =~ /\$(\w+)/)
    {
        if (! $validVariableNames{$1} or $min =~ /\$.+\$/){ $badMin = 'true';}
    }
    if ($max and $max =~ /\$(\w+)/)
    {
        if (! $validVariableNames{$1} or $max =~ /\$.+\$/){ $badMax = 'true';}
    }
    if ($inc and $inc =~ /\$(\w+)/)
    {
        if (! $validVariableNames{$1} or $inc =~ /\$.+\$/){ $badInc = 'true';}
    }
    if($name)                                       # If a name was entered, this is a valid variable
    {
      $inc = 1 unless ($inc);                       # Set default increment value
      if($validVariableNames{$name})
      {
        push(@{$errorList{'Beginning Variables'}}, "Variable #" . ($i+1) . " has a name already in use");
        $errorFlag = 1;
      }
      elsif($name =~ m/$ILLEGAL/ or $name =~ m/(^_)|(_$)/)
      {
        push(@{$errorList{'Beginning Variables'}}, "Variable $name has illegal characters in its name");
        $errorFlag = 1;
      }
      elsif(not $min)
      {
        push(@{$errorList{'Beginning Variables'}}, "Variable $name has a missing MIN value");
        $errorFlag = 1;
      }
      elsif(not $max)
      {
        push(@{$errorList{'Beginning Variables'}}, "Variable $name has a missing MAX value");
        $errorFlag = 1;
      }
      elsif($min !~ $NUMBER && $badMin eq 'true')
      {
        push(@{$errorList{'Beginning Variables'}}, "Variable $name has a MIN($min) value of unknown format");
        $errorFlag = 1;
      }
      elsif($max !~ $NUMBER && $badMax eq 'true')
      {
        push(@{$errorList{'Beginning Variables'}}, "Variable $name has a MAX($max) value of unknown format");
        $errorFlag = 1;
      }
      elsif($inc !~ $NUMBER && $badInc eq 'true')
      {
        push(@{$errorList{'Beginning Variables'}}, "Variable $name has a INC($inc) value of unknown format");
        $errorFlag = 1;
      }
      elsif($min > $max  && $min !~/\$/ && $max !~/\$/)
      {
        push(@{$errorList{'Beginning Variables'}}, "Variable $name has a MIN value greater than its MAX value");
        $errorFlag = 1;
      }
      elsif(defined $nonzero)
      {
        push(@variables, "\$$name = non_zero_random($min, $max, $inc);");
      }
      else
      {
        push(@variables, "\$$name = random($min, $max, $inc);");
      }
      $validVariableNames{$name} = 'valid';
    }
  }

  # Get intermediate values
  $varTableCount = $q->param('intvartable');
  for(my $i = 0; $i < $varTableCount; $i++)
  {
    my ($name, $exp) = ($q->param("ivName$i"), $q->param("ivExp$i"));
    if($name and $name =~ m/^\$(.+)/){$name = $1;}  # Remove '$' from start of variable, if it exists
    if($name)                                       # If a name was entered, this is a valid variable
    {
      if($validVariableNames{$name})
      {
        push(@{$errorList{'Intermediate Variables'}}, "Variable #" . ($i+1) . " has a name already in use");
        $errorFlag = 1;
      }
      elsif($name =~ $ILLEGAL or $name =~ m/(^_)|(_$)/)
      {
        push(@{$errorList{'Intermediate Variables'}}, "Variable $name has illegal characters in its name");
        $errorFlag = 1;
      }
      elsif(not $exp)
      {
        push(@{$errorList{'Intermediate Variables'}}, "Variable $name is missing an expression");
        $errorFlag = 1;
      }  
      else
      {
        $exp =~ s/;\s*$//;           # Remove semicolon, if one exists
        push(@intVariables, "\$$name = $exp;");
      }
      $validVariableNames{$name} = 'valid';
    }
  }

  # Get question type
  $qType = $q->param('qType');
  if(not $qtypes{$qType})
  {
    push(@{$errorList{'Question Type'}}, 'No valid question type was selected');
    $errorFlag = 1;
  }

  # Critical point, quit if errors were detected
  if($errorFlag){return ($errorFlag, %errorList);}

  # Get answer by question type
  if($qType eq 'MC')         # Multiple choice (@mcNormal, @mcAddOns, @mcCorrect, @mcquestions, @mcrandom)
  {
    my ($nofq, $nota, $aota, $correction, $questionText, $rand, $mcCorrect);
    my $mcTableSize = $q->param('mctable');
    for(my $i = 0; $i < $mcTableSize; $i++)
    {
      my (@temp, @mcA, @Extras);
      push(@temp, $q->param("mcqA$i"),$q->param("mcqB$i"),$q->param("mcqC$i"),$q->param("mcqD$i"),$q->param("mcqE$i"),$q->param("mcqF$i"));
      $mcCorrect  = $q->param("mca$i");         # Answer marked correct
      $nota = $q->param("nota$i");              # Checkbox for 'None of the Above'
      $aota = $q->param("aota$i");              # Checkbox for 'All of the Above'
      $rand = $q->param("rand$i");
      my @tempfull = (@temp, $aota, $nota);
      $nota = (($nota) ? 'yes' : 'no');
      $aota = (($aota) ? 'yes' : 'no');
      $rand = (($rand) ? 'yes' : 'no');
      $questionText = $q->param("mcQuest$i");
      $questionText =~ s/^\s*\b(.*)\b\s*$/$1/s;     # Strip leading and trailing whitspace
      if((not $questionText) and ($i == 0))         # Check to make sure i = 0 has valid question
      {
        push(@{$errorList{'Multiple Choice'}}, 'Missing question text for question 1');
        $errorFlag = 1;
      }
      elsif(not $questionText){}
      elsif(not defined $mcCorrect)
      {
        push(@{$errorList{'Multiple Choice'}}, 'No correct answer indicated');
        $errorFlag = 1;
      }
      elsif(not $tempfull[$mcCorrect])
      {
        push(@{$errorList{'Multiple Choice'}}, 'Answer marked correct is out of bounds or is blank in question ' . ($i+1));
        $errorFlag = 1;
      }
      else
      {
        $questionText =~ s/\x0D\x0A|\n/ \$BR /g;            # \n -> $BR for Windows and others
        $questionText =~ s/ANSWER/\\{ans_rule\(10\)\\}/g;   # ANSWER -> \{ans_rule(10)\}   not case sensitive
        $questionText =~ s/PICTURE\((\w+\.\w+)\)/"\.image\("$1"\)\."/g; # PICTURE(name)
        $questionText =~ s/"/~~"/g;                         # Question can't have bare double quotes

## Edit by Mark Schmitt 7/16
# @mcA will only contain wrong answers
# $mcCorrect[$i] will contain the correct answer for question $i

# I worry about how this will work with AOTA and NOTA.  I will need to test those cases
    if ($mcCorrect == 6)
    {
      $mcCorrect[$i] = 'All of the Above';
    }
    elsif ($mcCorrect == 7)
    {
      $mcCorrect[$i] = 'None of the Above';
    }
    else
    {
      $mcCorrect[$i] = $temp[$mcCorrect];
    }
    foreach (0..5)
    {
      if ($temp[$_] ne '' && $temp[$_] ne $mcCorrect[$i])
      {
        push(@mcA,$temp[$_]);
      }
    }
# Edit by Mark Schmitt
# This guarantees that @Extras always has some data, which in turn
# guarantees that @mcAddOns is defined.  This is to patch an error when no AddOns are selected.
        if($aota eq 'yes'){push(@Extras, 'All of the Above');}
        if($nota eq 'yes'){push(@Extras, 'None of the Above');}
        if($aota ne 'yes' && $nota ne 'yes'){push(@Extras,'NO ADDONS');}
        $nofq = @mcA+1;                                          # Get number of correct answers
        if($nofq < 2)
        {
          push(@{$errorList{'Multiple Choice'}}, 'At least two answer choices must be selected (other than All and None of the Above)');
          $errorFlag = 1;
        }
        elsif($mcCorrect[$i] eq '')
        {
          push(@{$errorList{'Multiple Choice'}}, 'Answer marked correct is blank');
          $errorFlag = 1;
        }
        else
        {
          $mcNormal[$i] = \@mcA;
          $mcquestions[$i] = $questionText;
          $mcrandom[$i] = $rand;
# Edit by Mark Schmitt
# changed the definition of @mcAddOns so that the array is always defined
          $mcAddOns[$i] = \@Extras;
          }
      }
    }
  }
  elsif($qType eq 'TF')      # True/False    (@tfquestions, @tfAns)
  {
    my $choose = $q->param('tfchoose');
    my $tfTableSize = $q->param('tftable');
    for(my $i = 0; $i < $tfTableSize; $i++)
    {
      my $answer = $q->param("tfans$i");
      my $questionText = $q->param("tfQuest$i");
      $questionText =~ s/^\s*\b(.*)\b\s*$/$1/s;     # Strip leading and trailing whitspace
      if((not $questionText) and ($i == 0))         # Check to make sure i = 0 has valid question
      {
        push(@{$errorList{'True/False'}}, 'Missing question text for question ' . ($i+1));
        $errorFlag = 1;
      }
      elsif(not $questionText){}
      elsif(not $answer)
      {
        push(@{$errorList{'True/False'}}, 'No correct answer indicated on question ' . ($i+1));
        $errorFlag = 1;
      }
      else
      {
        $questionText =~ s/\x0D\x0A|\n/ \$BR /g;            # \n -> $BR for Windows and others
        $questionText =~ s/ANSWER/\\{ans_rule\(10\)\\}/g;   # ANSWER -> \{ans_rule(10)\}   not case sensitive
        $questionText =~ s/PICTURE\((\w+\.\w+)\)/"\.image\("$1"\)\."/g; # PICTURE(name)
        $questionText =~ s/"/~~"/g;                         # Question can't have bare double quotes
        $answer = (($answer =~ m/true/i) ? 'T' : 'F');
        push(@tfquestions, $questionText);
        push(@tfAns, $answer);
      }
    }
    if(not $choose){$tfchoose = @tfquestions;}
    elsif($choose < 1 or $choose > @tfquestions)
    {
      push(@{$errorList{'True/False'}}, 'Choose value out of range');
      $errorFlag = 1;
    }
    else{$tfchoose = $choose;}
  }

## edit by Mark Schmitt
## added capabilities for Matching questions  
    elsif($qType eq 'Match')      # Matching    (@matchquestions, @matchAns)
  {
    my $choose = $q->param('matchchoose');
    my $matchTableSize = $q->param('matchtable');
    for(my $i = 0; $i < $matchTableSize; $i++)
    {
      my $answer = $q->param("matchAns$i");
      my $questionText = $q->param("matchQuest$i");
      $questionText =~ s/^\s*\b(.*)\b\s*$/$1/s;     # Strip leading and trailing whitspace
      if((not $questionText) and ($i == 0))         # Check to make sure i = 0 has valid question
      {
        push(@{$errorList{'Matching'}}, 'Missing question text for question ' . ($i+1));
        $errorFlag = 1;
      }
      elsif(not $questionText){}
      elsif(not $answer)
      {
        push(@{$errorList{'Matching'}}, 'No correct answer indicated on question ' . ($i+1));
        $errorFlag = 1;
      }
      else
      {
        $questionText =~ s/\x0D\x0A|\n/ \$BR /g;            # \n -> $BR for Windows and others
        $questionText =~ s/ANSWER/\\{ans_rule\(10\)\\}/g;   # ANSWER -> \{ans_rule(10)\}   not case sensitive
        $questionText =~ s/PICTURE\((\w+\.\w+)\)/"\.image\("$1"\)\."/g; # PICTURE(name)
        $questionText =~ s/"/~~"/g;                         # Question can't have bare double quotes

        push(@matchquestions, $questionText);
        push(@matchAns, $answer);
      }
    }
    if(not $choose){$matchchoose = @matchquestions;}
    elsif($choose < 1 or $choose > @matchquestions)
    {
      push(@{$errorList{'Matching'}}, 'Choose value out of range');
      $errorFlag = 1;
    }
    else{$matchchoose = $choose;}
  }
  elsif($qType eq 'FITB')    # Fill-in-the-Blank
  {
    # Get and Process Question Text
    my $questionText = $q->param('Quest');
    $questionText =~ s/^\s*\b(.*)\b\s*$/$1/s;     # Strip leading and trailing whitspace
    if(not $questionText)
    {
      push(@{$errorList{'Fill-in-the-blank'}}, "Question is blank");
      $errorFlag = 1;
    }
    else
    {
      $questionText =~ s/\x0D\x0A|\n/ \$BR /g;            # \n -> $BR for Windows and others
      $questionText =~ s/ANSWER/\\{ans_rule\(10\)\\}/g;   # ANSWER -> \{ans_rule(10)\}
      $questionText =~ s/PICTURE\((\w+)\)/\\{image\($1\)\\}/g; # PICTURE(name)
      $questionFITB = $questionText;
    }

    my $fitbAnswerTableSize = $q->param('anstable');
    for(my $i = 0; $i < $fitbAnswerTableSize; $i++)
    {
      my $type = $q->param("anstype$i");
      my $text = $q->param("ansText$i");
      $text =~ s/^\s*\b(.*)\b\s*$/$1/;     # Strip leading and trailing whitspace
      if($text)
      {
        if(not $type)
        {
          push(@{$errorList{'Fill-in-the-blank'}}, 'No type selected for answer ' . ($i+1));
          $errorFlag = 1;
        }
        elsif($type eq 'text')
        {
          my $checkCase = $q->param("textcase$i");
          if($checkCase)
          {
            push(@fitbLines, qq/&ANS(str_cmp("$text"));/);
          }
          else
          {
            push(@fitbLines, qq/&ANS(str_cmp("$text", 'ignore_case'));/);
          }
        }
        elsif($type eq 'number')
        {
          my $strict = $q->param("numstrict$i");
          my $tol    = $q->param("numtol$i");
          my $gtype  = $q->param("numttype$i");
          $tol =~ s/^\s*\b(.*)\b\s*$/$1/;      # Strip leading and trailing whitspace

          $strict = (($strict) ? 'strict' : 'std');

          if(not defined($tol))
          {
            push(@fitbLines, qq/&ANS(num_cmp("$text", mode => '$strict'));/);
          }
          elsif($tol !~ $NUMBER)
          {
            push(@{$errorList{'Fill-in-the-blank'}}, "Tolerance($gtype) must be given as a number for answer " . ($i+1));
            $errorFlag = 1;
          }
          elsif(not $gtype)
          {
            push(@{$errorList{'Fill-in-the-blank'}}, 'Tolerance missing type for answer ' . ($i+1));
            $errorFlag = 1;
          }
          elsif($gtype eq 'relative')
          {
            if($tol > 100 or $tol < 0)
            {
              push(@{$errorList{'Fill-in-the-blank'}}, 'Tolerance must be between 0 and 100 for relative mode in answer ' . ($i+1));
              $errorFlag = 1;
            }
            push(@fitbLines, qq/&ANS(num_cmp("$text", mode => '$strict', reltol => '$tol'));/);
          }
          elsif($gtype eq 'absolute')
          {
            push(@fitbLines, qq/&ANS(num_cmp("$text", mode => '$strict', tol => '$tol'));/);
          }
          else
          {
            push(@{$errorList{'Fill-in-the-blank'}}, 'Tolerance type unknown for answer ' .($i+1));
            $errorFlag = 1;
          }
        }
        elsif($type eq 'function')
        {
          my $vars = $q->param("funcvars$i");
          $vars =~ s/^\s*\b(.*)\b\s*$/$1/;     # Strip leading and trailing whitspace
          if(not $vars)
          {
            push(@{$errorList{'Fill-in-the-blank'}}, 'Missing variables in answer ' . ($i+1));
            $errorFlag = 1;
          }
          else
          {
            my @varlist = split(/,/, $vars);
            foreach(@varlist)
            {
              if($_ =! /$ILLEGAL|_/)
              {
                push(@{$errorList{'Fill-in-the-blank'}}, 'Illegal characters in variable answer ' . ($i+1));
                $errorFlag = 1;
              }
              $_ = "'$_'";
            }
            push(@fitbLines, qq/&ANS(func_cmp("$text", vars=>['/ . join(', ', @varlist) . qq/']));/);
          }
        }
        elsif($type eq 'unit')
        {
          my $strict = $q->param("unitstrict$i");
          my $tol    = $q->param("unittol$i");
          my $gtype  = $q->param("unitttype$i");
          my $unit   = $q->param("unitunit$i");
          $tol =~ s/^\s*\b(.*)\b\s*$/$1/;      # Strip leading and trailing whitspace
          $unit =~ s/^\s*\b(.*)\b\s*$/$1/;     # Strip leading and trailing whitspace

          $strict = (($strict) ? 'strict' : 'std');

          if(not $unit)
          {
            push(@{$errorList{'Fill-in-the-blank'}}, 'Unit missing for answer ' . ($i+1));
            $errorFlag = 1;
          }
          elsif(not $tol)
          {
            push(@fitbLines, qq/&ANS(num_cmp("$text", mode => '$strict', unit => '$unit'));/);
          }
          elsif($tol !~ $NUMBER)
          {
            push(@{$errorList{'Fill-in-the-blank'}}, "Tolerance($tol) must be given as a number for answer " . ($i+1));
            $errorFlag = 1;
          }
          elsif(not $gtype)
          {
            push(@{$errorList{'Fill-in-the-blank'}}, 'Tolerance missing type for answer ' . ($i+1));
            $errorFlag = 1;
          }
          elsif($gtype eq 'relative')
          {
            if($tol > 100 or $tol < 0)
            {
              push(@{$errorList{'Fill-in-the-blank'}}, 'Tolerance must be between 0 and 100 for relative mode in answer ' . ($i+1));
              $errorFlag = 1;
            }
            push(@fitbLines, qq/&ANS(num_cmp("$text", mode => '$strict', reltol => '$tol', unit => '$unit'));/);
          }
          elsif($gtype eq 'absolute')
          {
            push(@fitbLines, qq/&ANS(num_cmp("$text", mode => '$strict', tol => '$tol', unit => '$unit'));/);
          }
          else
          {
            push(@{$errorList{'Fill-in-the-blank'}}, 'Tolerance type unknown for answer ' .($i+1));
            $errorFlag = 1;
          }
        }
        else
        {
          push(@{$errorList{'Fill-in-the-blank'}}, "Unknown answer type($qType) in answer " . ($i+1));
          $errorFlag = 1;
        }
      }
    }
  }
  else   # We should never get to this point, unless a new type is added to %qtypes without adding code above
  {
    push(@{$errorList{'Question Type'}}, "No handler was written for this question type($qType)");
    $errorFlag = 1;
  }

  # Critical point, quit if errors were detected
  if($errorFlag){return ($errorFlag, %errorList);}
  
  # Write file
  if(-e "$STORE_DIRECTORY/$fileName.pg")
  {
    push(@{$errorList{'System'}}, "Question name already exists");
    $errorFlag = 1;
  }
  elsif(open(FILE, ">$STORE_DIRECTORY/$fileName.pg"))                        # Try to open file for writing
  #elsif(open(FILE, "|/usr/sbin/sendmail -t"))
  {
    flock(FILE, 8);                                                          # Lock file to protect contents
   # print FILE "To: MSchmitt\@dcds.edu\nFrom: cb84084\@ltu.edu\n";
   # print FILE "Subject: DCDS New Question\n\n";
    print FILE "# $fileName.pg\n";                                           # Question name
    print FILE "# Question Type: $qType\n";
    if(@comments){print FILE join("\n", @comments), "\n\n";}                 # Question Comments
    print FILE "DOCUMENT();\n\n";                                            # First executable line of code
    print FILE "loadMacros(", join(",\n", @includes), ");\n\n";              # Set macros
    print FILE "TEXT(&beginproblem);\n\$showPartialCorrectAnswers = 0;\n\n"; # Start question, turn off partial answers
    if(@variables){print FILE join("\n\n", @variables), "\n\n";}             # Beginning Variables
    if(@intVariables){print FILE join("\n\n", @intVariables), "\n\n";}       # Intermediate Variables

    if($qType eq 'FITB')
    {
      print FILE "BEGIN_TEXT\n";                                             # Start Question Text
      print FILE "$questionFITB\n";                                          # Question(s)
      print FILE "END_TEXT\n\n";                                             # End Question Text
      print FILE join("\n\n", @fitbLines), "\n\n";                           # Answer(s) to question(s)
    }
    elsif($qType eq 'MC')
    {
      my $size = @mcquestions;
      for(my $i = 0; $i < $size; $i++)
      {
        print FILE qq/\$mc$i = new_multiple_choice();\n\n/;
        print FILE qq/\$mc$i->qa("/, $mcquestions[$i], qq/",\n"/, $mcCorrect[$i], qq/");\n\n/;
        if($mcrandom[$i] eq 'yes')
        {
          print FILE qq/\$mc$i->extra(\n\t"/;
          print FILE join(qq/",\n\t"/, @{$mcNormal[$i]});
          print FILE qq/");\n\n/;
        }
        else
        {
          foreach(@{$mcNormal[$i]})
          {
            print FILE qq/\$mc$i->makeLast("$_");\n\n/;
          }
        }
        foreach(@{$mcAddOns[$i]})
        {
# Edit by Mark Schmitt
# Added conditional to avoid error when no makeLast is needed.
            if ($_ ne 'NO ADDONS'){
                print FILE qq/\$mc$i->makeLast("$_");\n\n/;}
        }
        print FILE qq/BEGIN_TEXT\n/;
        print FILE qq/\\{\$mc$i->print_q\\}\n\$PAR\n\\{\$mc$i->print_a\\}\n/;
        print FILE qq/END_TEXT\n\n/;
        print FILE qq/ANS(str_cmp(\$mc$i->correct_ans));\n\n/;
      }
    }
    elsif($qType eq 'TF')
    {
      my $size = @tfquestions;
      print FILE qq/\$tf = new_select_list();\n\n/;                          # Create TF object
      print FILE qq/\$tf->qa(\n/;                                            # Add question/answer to TF object
      for(my $i = 0; $i < $size; $i++)
      {
        my $question = shift(@tfquestions);
        my $answer = shift(@tfAns);
        print FILE qq/"$question",\n"$answer",\n/;                           # Add question/answer to TF object
      }
      print FILE qq/);\n\n/;
      print FILE qq/\$tf->choose($tfchoose);\n\n/;
      print FILE qq/BEGIN_TEXT\n/;                                           # Start Question Text
      print FILE qq/\\\{\$tf->print_q\\\}\n/;                                    # Question/Answer box
      print FILE qq/END_TEXT\n\n/;                                           # End Question Text
      print FILE qq/ANS(str_cmp(\$tf->ra_correct_ans));\n\n/;                # Instructions for correct answers
    }

# Edit by Mark Schmitt
# added section for Matching capabilities  
  elsif($qType eq 'Match')
    {
      my $size = @matchquestions;
      print FILE qq/\$match = new_match_list();\n\n/;                          # Create TF object
      print FILE qq/\$match->qa(\n/;                                            # Add question/answer to TF object
      for(my $i = 0; $i < $size; $i++)
      {
        my $question = shift(@matchquestions);
        my $answer = shift(@matchAns);
        print FILE qq/"$question",\n"$answer",\n/;                           # Add question/answer to TF object
      }
      print FILE qq/);\n\n/;
      print FILE qq/\$match->choose($matchchoose);\n\n/;
      print FILE qq/BEGIN_TEXT\n/;                                           # Start Question Text
      print FILE qq/\\\{\$match->print_q\\\}\n/;                                    # Question/Answer box
      print FILE qq/\\\{\$match->print_a\\\}\n/;                                    # Question/Answer box
      print FILE qq/END_TEXT\n\n/;                                           # End Question Text
      print FILE qq/ANS(str_cmp(\$match->ra_correct_ans));\n\n/;                # Instructions for correct answers
    }
    print FILE "ENDDOCUMENT();\n";                                           # Last line of executable code
   flock(FILE, 2);                                                          # Unlock file, since we're done with it
    close(FILE);                                                             # Close file. We are done.
## Edit by Mark Schmitt
## reset the group and permissions on the output
## COURSE SPECIFIC DATA
## in chown, customize userpid and groupid
   chown 501,502,"$STORE_DIRECTORY/$fileName.pg";
   chmod 0770,"$STORE_DIRECTORY/$fileName.pg";
  }
  else
  {
    push(@{$errorList{'System'}}, "Unable to write question to disk");
    $errorFlag = 1;
  }

  return ($errorFlag, %errorList);
};

my $submit = $q->param('submit');
$submit = 'firstTime' unless defined $submit;

my ($errors, %errorList);

if($submit eq 'Write Question to File')
{
  ($errors, %errorList) = checkAndWriteQuestion();
  if(not $errors)
  {
    print $q->start_html({-bgcolor=>'white', title=>'New Question Created'}),
          $q->h2({-style=>'text-align:center'}, 'New Question Created'),
          $q->p({-style=>'font-size:smaller'}, $q->center('Your question was successfully created and stored.'));
## NEW EDIT
## COURSE SPECIFIC DATA
    print $q->a({-href=>$SCRIPT_NAME},'Create Another Question');
    exit;
  }
}

my $questionType = $q->param('qType');
my $varTableSize = $q->param('vartable');
my $fitbAnswerTableSize = $q->param('anstable');
my $intvarTableSize = $q->param('intvartable');
my $mcTableSize = $q->param('mctable');
my $tfTableSize = $q->param('tftable');
my $matchTableSize = $q->param('matchtable');
$varTableSize = 4 unless defined $varTableSize;
$fitbAnswerTableSize = 3 unless defined $fitbAnswerTableSize;
$intvarTableSize = 3 unless defined $intvarTableSize;
$mcTableSize = 1 unless defined $mcTableSize;
$tfTableSize = 2 unless defined $tfTableSize;
$matchTableSize = 4 unless defined $matchTableSize;
$questionType = 'FITB' unless defined $questionType;

my ($nameAlreadyExists);
my $section = 'A';

print $q->start_html({-bgcolor=>'white', title=>'Create New Question'}),
      $q->h2({-style=>'text-align:center'}, 'Create New Question');

if($errors)
{
  my ($errorTitle);
  print '<font color="red">', $q->center($q->font({-size=>'+1'}, 'The following errors were detected while attempting to build your question:')), $q->br();
  foreach $errorTitle (sort keys %errorList)
  {
    if($errorTitle eq 'flagNameAlreadyExists'){$nameAlreadyExists = 'true';}
    else
    {
      print $q->center($q->b("$errorTitle:"),
                       $q->br(),
                       join($q->br, @{$errorList{$errorTitle}}),
                       $q->br());
    }
  }
  print '</font>';
}

## COURSE SPECIFIC DATA
# Change Speech3.pl to the localname of the script
print $q->start_form({-method=>'post', -action=>$SCRIPT_NAME, -name=>'theForm'}),
      $q->start_table({-width=>'100%'});
print $q->Tr($q->td({-width=>'5%'}, '&nbsp;'),
             $q->td({-width=>'90%'}, $q->hr()),
             $q->td({-width=>'5%'}, '&nbsp;'));
# Edit by Mark Schmitt
# Added section to select proper directory
print $q->Tr($q->td('&nbsp;'),
             $q->td($q->start_table({-width=>'100%'}),
                    $q->Tr($q->td({-width=>'40%'}, $q->b($section++ . ') Select the proper directory for your question:')),
                           $q->td({-width=>'60%'}, $q->popup_menu({-name=>'qDirectory', -values=>\@qDirectory, -labels=>\%qDirectories}),
#                                                   $q->submit({-name=>'submit', -value=>'Change Directory'})
)),
                    $q->end_table(),
                    $q->hr()),
                    $q->td('&nbsp;'));
#
print $q->Tr($q->td('&nbsp;'),
             $q->td($q->start_table({-width=>'100%'}),
                    $q->Tr($q->td({-width=>'70%'}, $q->b($section++ . ') Select the name of this question:'),
                                                   '&nbsp;&nbsp;',
                                                   $q->textfield({-name=>'qName', -size=>'35'})),
                           $q->td({-width=>'30%'}, (($nameAlreadyExists)?$q->checkbox({-name=>'overwritename', -value=>'overwrite', -label=>"Overwrite existing"}):''))),
                    $q->end_table(),
                    $q->hr()),
             $q->td('&nbsp;'));
print $q->Tr($q->td('&nbsp;'),
             $q->td($q->start_table({-width=>'100%'}),
                    $q->Tr($q->td({-width=>'40%'}, $q->b($section++ . ') Select the type of question:')),
                           $q->td({-width=>'60%'}, $q->popup_menu({-name=>'qType', -values=>\@qtype, -labels=>\%qtypes}),
                                                   $q->submit({-name=>'submit', -value=>'Change type'}))),
                    $q->end_table(),
                    $q->hr()),
             $q->td('&nbsp;'));
             
print $q->Tr($q->td('&nbsp;'),
             $q->td($q->start_table({-width=>'100%'}),
                    $q->Tr($q->td({-width=>'100%'}, $q->b($section++ . ') Check any optional macros you wish to include'))),
                    $q->Tr($q->td({-style=>'font-size:smaller'}, $q->i('All manditory macros are automatically included.'))),
                    $q->Tr($q->td($q->start_table({-width=>'100%'}),
                                  $q->Tr($q->td({-width=>'33%'}, $q->checkbox({-name=>'includes', -label=>'Complex Numbers',          -value=>'PGcomplexmacros.pl'})),
                                         $q->td({-width=>'33%'}, $q->checkbox({-name=>'includes', -label=>'Differential Equations',   -value=>'PGdiffeqmacros.pl'})),
                                         $q->td({-width=>'33%'}, $q->checkbox({-name=>'includes', -label=>'Matrices',                 -value=>'PGmatrixmacros.pl'}))),
                                  $q->Tr($q->td({-width=>'33%'}, $q->checkbox({-name=>'includes', -label=>'Special Number Functions', -value=>'PGnumericalmacros.pl'})),
                                         $q->td({-width=>'33%'}, $q->checkbox({-name=>'includes', -label=>'Polynomials',              -value=>'PGpolynomialmacros.pl'})),
                                         $q->td({-width=>'33%'}, $q->checkbox({-name=>'includes', -label=>'Statistics',               -value=>'PGstatisticsmacros.pl'}))),
                                  $q->end_table())),
                    $q->end_table(),
                    $q->hr()),
             $q->td('&nbsp;'));
print $q->Tr($q->td('&nbsp;'),
             $q->td($q->start_table({-width=>'100%'}),
                    $q->Tr($q->td({-width=>'100%'}, $q->b($section++ . ') Enter any comments you wish:'))),
                    $q->Tr($q->td({-style=>'font-size:smaller'}, $q->i('These will not appear in the question, ',
                                  'but will allow you to include reminders to yourself should you have to go back ',
                                  'and edit this question.'))),
                    $q->Tr($q->td($q->center($q->textarea({-name=>'comments', -rows=>'5', -cols=>'70', -wrap=>'off'})))),
                    $q->end_table(),
                    $q->hr()),
             $q->td('&nbsp;'));
print $q->Tr($q->td('&nbsp;'),
             $q->td($q->start_table({-width=>'100%'}),
                    $q->Tr($q->td({-width=>'100%'}, $q->b($section++ . ') Set names and ranges for any variables you wish to use (these need not appear in the question text):'))),
                    $q->Tr($q->td({-style=>'font-size:smaller'}, $q->i(q(Use integer, decimal, and scientific notation for min/max values. All variables must begin with a '$'.  Min/Max/Inc may be simple expressions in terms of ONE previously defined variable.)))),
                    $q->end_table()),
             $q->td('&nbsp;'));
print '<tr>',
            $q->td('&nbsp;'),
            '<td>',
            $q->start_table({-width=>'100%'});
 
for(my $i = 0; $i < $varTableSize; $i++)
{
  print $q->Tr($q->td({-width=>'7%'}, '&nbsp;'),
               $q->td({-width=>'20%'}, 'Name:&nbsp;',      $q->textfield({-name=>"gvName$i", -size=>'10', -maxlength=>'20'})),
               $q->td({-width=>'15%'}, 'Min:&nbsp;',       $q->textfield({-name=>"gvMin$i",  -size=>'5',  -maxlength=>'10'})),
               $q->td({-width=>'15%'}, 'Max:&nbsp;',       $q->textfield({-name=>"gvMax$i",  -size=>'5',  -maxlength=>'10'})),
               $q->td({-width=>'20%'}, 'Increment:&nbsp;', $q->textfield({-name=>"gvInc$i",  -size=>'5',  -maxlength=>'15'})),
               $q->td({-width=>'15%'}, 'Non-zero:&nbsp;',  $q->checkbox({-name=>"gvNonzero$i", -value=>'nonzero', -label=>''})),
               $q->td({-width=>'8%'}, '&nbsp;'))
}

print $q->end_table(),
      $q->start_table({-width=>'100%'}),
      $q->Tr($q->td({-width=>'100%'}, 'Resize table to ', 
                                      $q->textfield({-name=>'vartable', -size=>'3', -value=>$varTableSize}),
                                      ' entries. ',
                                      $q->submit({-name=>'submit', -value=>'Resize Table'}))),
      $q->end_table(),
      $q->hr(),
      '</td>',
      $q->td('&nbsp;'),
      '</tr>';
      
print $q->Tr($q->td('&nbsp;'),
             $q->td($q->start_table({-width=>'100%'}),
                    $q->Tr($q->td({-width=>'100%'}, $q->b($section++ . ') Set names and values for any intermediate variables or constants you wish to use (these need not appear in the question text):'))),
                    $q->Tr($q->td({-style=>'font-size:smaller'}, $q->i(q(Use standard mathematic expressions. All names must begin with a '$'.)))),
                    $q->end_table()),
             $q->td('&nbsp;'));
print '<tr>',
            $q->td('&nbsp;'),
            '<td>',
            $q->start_table({-width=>'100%'});
 
for(my $i = 0; $i < $intvarTableSize; $i++)
{
  print $q->Tr($q->td({-width=>'7%'}, '&nbsp;'),
               $q->td({-width=>'20%'}, 'Name:&nbsp;', $q->textfield({-name=>"ivName$i", -size=>'10', -maxlength=>'20'})),
               $q->td({-width=>'65%'}, 'Expression:&nbsp;', $q->textfield({-name=>"ivExp$i", -size=>'55', -maxlength=>'100'})),
               $q->td({-width=>'8%'}, '&nbsp;'))
}

print $q->end_table(),
      $q->start_table({-width=>'100%'}),
      $q->Tr($q->td({-width=>'100%'}, 'Resize table to ', 
                                      $q->textfield({-name=>'intvartable', -size=>'3', -value=>$intvarTableSize}),
                                      ' entries. ',
                                      $q->submit({-name=>'submit', -value=>'Resize Table'}))),
      $q->end_table(),
      $q->hr(),
      '</td>',
      $q->td('&nbsp;'),
      '</tr>';

if($questionType eq 'FITB')
{
  print $q->Tr($q->td('&nbsp;'),
               $q->td($q->start_table({-width=>'100%'}),
                      $q->Tr($q->td({-width=>'100%'}, $q->b($section++ . ') Enter text of question:'))),
                      $q->Tr($q->td({-style=>'font-size:smaller'},
                         $q->i('Use ANSWER as a placeholder for where you want ',
                         'the input box to go. If you have multiple answer boxes, they will be graded in ',
                         'the order you place them below (i.e. the first occurance of ANSWER in your question ',
                         'will use the first table entry).'))),
                      $q->Tr($q->td($q->center($q->textarea({-name=>'Quest', -rows=>'10', -cols=>'70', -wrap=>'off'})))),
                      $q->end_table(),
                      $q->hr()),
               $q->td('&nbsp;'));
  print '<tr>',
        $q->td('&nbsp;'),
        '<td>',
        $q->start_table({-width=>'100%'}),
        $q->Tr($q->td({-width=>'100%'}, $q->b($section++ . ') Complete the table below:'))),
        $q->end_table(),
        $q->start_table({-width=>'100%'});

  for(my $i = 0; $i < $fitbAnswerTableSize; $i++)
  {
    my ($typeText, $typeNumb, $typeFunc, $typeUnit);
    my @tol = ('relative', 'absolute');
    my %tollabels = ('relative'=>'Relative', 'absolute'=>'Absolute');
    my $anstype = $q->param("anstype$i");
    $anstype = 'text' unless defined $anstype;
    $typeText = (($anstype eq 'text')?'checked':'');
    $typeNumb = (($anstype eq 'number')?'checked':'');
    $typeFunc = (($anstype eq 'function')?'checked':'');
    $typeUnit = (($anstype eq 'unit')?'checked':'');
    print $q->Tr($q->td({-width=>'7%'},  ($i+1)),
                 $q->td({-width=>'15%'}, 'Correct&nbsp;Answer:'),
                 $q->td({-colspan=>'3'}, $q->textfield({-name=>"ansText$i", -size=>'55'})),
                 $q->td({-width=>'8%'},  '&nbsp;')),
          $q->Tr($q->td({-width=>'7%'},  '&nbsp;'),
                 $q->td({-width=>'15%'}, qq(<input name="anstype$i" type="radio" value="text" $typeText>Text)),
                 $q->td({-colspan=>'3'}, $q->checkbox({-name=>"textcase$i", -value=>'usecase', -label=>'Case Sensitive'})),
                 $q->td({-width=>'8%'},  '&nbsp;')),
          $q->Tr($q->td({-width=>'7%'},  '&nbsp;'),
                 $q->td({-width=>'15%'}, qq(<input name="anstype$i" type="radio" value="number" $typeNumb>Numerical)),
                 $q->td({-width=>'15%'}, $q->checkbox({-name=>"numstrict$i", -value=>'strict', -label=>'Use Strict'})),
                 $q->td({-width=>'35%'}, 'Tolerance&nbsp;',
                                         $q->textfield({-name=>"numtol$i", -size=>'5'}),
                                         '&nbsp;&nbsp;',
                                         $q->radio_group({-name=>"numttype$i", -values=>\@tol, -labels=>\%tollabels})),
                 $q->td({-width=>'20%'}, '&nbsp;'),
                 $q->td({-width=>'8%'},  '&nbsp;')),
          $q->Tr($q->td({-width=>'7%'},  '&nbsp;'),
                 $q->td({-width=>'15%'}, qq(<input name="anstype$i" type="radio" value="function" $typeFunc>Function)),
                 $q->td({-width=>'15%'}, 'Allowed&nbsp;variables'),
                 $q->td({-colspan=>'2'}, $q->textfield({-name=>"funcvars$i", -size=>'25'})),
                 $q->td({-width=>'8%'},  '&nbsp;')),
          $q->Tr($q->td({-width=>'7%'},  '&nbsp;'),
                 $q->td({-width=>'15%'}, qq(<input name="anstype$i" type="radio" value="unit" $typeUnit>Number/Unit)),
                 $q->td({-width=>'15%'}, $q->checkbox({-name=>"unitstrict$i", -value=>'strict', -label=>'Use Strict'})),
                 $q->td({-width=>'35%'}, 'Tolerance&nbsp;',
                                         $q->textfield({-name=>"unittol$i", -size=>'5'}),
                                         '&nbsp;&nbsp;',
                                         $q->radio_group({-name=>"unitttype$i", -values=>\@tol, -labels=>\%tollabels})),
                 $q->td({-width=>'20%'}, 'Unit:&nbsp;', $q->textfield({-name=>"unitunit$i", -size=>'7'})),
                 $q->td({-width=>'8%'},  '&nbsp;'));
  }

  print $q->end_table(),
        $q->start_table({-width=>'100%'}),
        $q->Tr($q->td({-width=>'100%'}, 'Resize table to ', $q->textfield({-name=>'anstable', -default=>$fitbAnswerTableSize, -size=>'3'}), ' entries. ', $q->submit({-name=>'submit', -value=>'Resize Table'}))),
        $q->end_table(),
        $q->hr(),
        '</td>',
        $q->td('&nbsp;'),
        '</tr>';
}
elsif($questionType eq 'TF')
{
  print '<tr>',
        $q->td('&nbsp;'),
        '<td>',
        $q->start_table({-width=>'100%'}),
        $q->Tr($q->td({-width=>'100%'}, $q->b($section++ . ') Fill in question and select correct answer:'))),
        $q->end_table(),
        $q->start_table({-width=>'100%'}),
        $q->Tr($q->td({-width=>'65%'}, 'Select how many of these questions to show at once (leave blank to show all):'),
               $q->td({-width=>'35%'}, $q->textfield({-name=>'tfchoose', -maxlength=>2, -size=>4}))),
        $q->end_table(),
        $q->start_table({-width=>'100%'});

  for(my $i = 0; $i < $tfTableSize; $i++)
  {
    print $q->Tr($q->td({-width=>'7%', -valign=>'top'}, ($i+1), ')'),
                 $q->td({-width=>'93%'}, $q->textarea({-name=>"tfQuest$i", -rows=>'2', -cols=>'70', -wrap=>'off'}))),
          $q->Tr($q->td('&nbsp;'),
                 $q->td($q->radio_group({-name=>"tfans$i", -values=>\@tfAns, -default=>'blank'})));
  }

  print $q->end_table(),
        $q->start_table({-width=>'100%'}),
        $q->Tr($q->td({-width=>'100%'}, 'Resize table to ', $q->textfield({-name=>'tftable', -default=>$tfTableSize, -size=>'3'}), ' entries. ', $q->submit({-name=>'submit', -value=>'Resize Table'}))),
        $q->end_table(),
        $q->hr(),
        '</td>',
        $q->td('&nbsp;'),
        '</tr>';
}

# Edit by Mark Schmitt
# Added code for Matching questions
elsif($questionType eq 'Match')
{
  print '<tr>',
        $q->td('&nbsp;'),
        '<td>',
        $q->start_table({-width=>'100%'}),
        $q->Tr($q->td({-width=>'100%'}, $q->b($section++ . ') Fill in question and correct answer:'))),
        $q->end_table(),
        $q->start_table({-width=>'100%'}),
        $q->Tr($q->td({-width=>'65%'}, 'Select how many of these questions to show at once (leave blank to show all):'),
               $q->td({-width=>'35%'}, $q->textfield({-name=>'matchchoose', -maxlength=>2, -size=>4}))),
        $q->end_table(),
        $q->start_table({-width=>'100%'});

  for(my $i = 0; $i < $matchTableSize; $i++)
  {
    print $q->Tr($q->td({-width=>'7%', -valign=>'top'}, ($i+1), ')'),
                 $q->td({-width=>'93%'}, $q->textarea({-name=>"matchQuest$i", -rows=>'2', -cols=>'70', -wrap=>'off'}))),
          $q->Tr($q->td('&nbsp;'),
                 $q->td({-width=>'8%'}, 'Correct&nbsp;Answer:'),
                 $q->td($q->textarea({-name=>"matchAns$i", -rows=>'1', -cols=>'20', -wrap=>'off'})));
  }

  print $q->end_table(),
        $q->start_table({-width=>'100%'}),
        $q->Tr($q->td({-width=>'100%'}, 'Resize table to ', $q->textfield({-name=>'matchtable', -default=>$matchTableSize, -size=>'3'}), ' entries. ', $q->submit({-name=>'submit', -value=>'Resize Table'}))),
        $q->end_table(),
        $q->hr(),
        '</td>',
        $q->td('&nbsp;'),
        '</tr>';
}
elsif($questionType eq 'MC')
{
  print '<tr>',
        $q->td('&nbsp;'),
        '<td>',
        $q->start_table({-width=>'100%'}),
        $q->Tr($q->td({-width=>'100%'}, $q->b($section++ . ') Fill in question, answers and correct answer:'))),
        $q->Tr($q->td({-style=>'font-size:smaller'}, $q->i('Fill-in between two and six options. Select the checkboxes as needed.'))),
        $q->end_table(),
        $q->start_table({-width=>'100%'});
        
  for(my $i = 0; $i < $mcTableSize; $i++)
  {
    my @mccorrect = ('','','','','','','','');
    my $mccorrans = $q->param("mca$i");
    $mccorrans = 8 unless defined $mccorrans;
    $mccorrect[$mccorrans] = 'checked';

    print $q->Tr($q->td({-valign=>'top'}, ($i+1),')'),
                 $q->td($q->start_table({-width=>'100%'}),
                        $q->Tr($q->td({-width=>'100%'}, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;', $q->textarea({-name=>"mcQuest$i", -rows=>'2', -cols=>'70', -wrap=>'off'}))),
                        $q->end_table(),
                        $q->start_table({-width=>'100%', -style=>'text-align:left'}),
                        $q->Tr($q->td({-width=>'5%'},  '&nbsp;'),
                               $q->td({-width=>'20%'}, $q->b('Answer&nbsp;A)')),
                               $q->td({-width=>'55%'}, $q->center($q->textfield({-name=>"mcqA$i", -size=>'40', -maxlength=>'128'}))),
                               $q->td({-width=>'20%'}, qq(<input type="radio" name="mca$i" value="0" $mccorrect[0]>&nbsp;Correct?))),
                        $q->Tr($q->td('&nbsp;'),
                               $q->td($q->b('Answer&nbsp;B)')),
                               $q->td($q->center($q->textfield({-name=>"mcqB$i", -size=>'40', -maxlength=>'128'}))),
                               $q->td(qq(<input type="radio" name="mca$i" value="1" $mccorrect[1]>&nbsp;Correct?))),
                        $q->Tr($q->td('&nbsp;'),
                               $q->td($q->b('Answer&nbsp;C)')),
                               $q->td($q->center($q->textfield({-name=>"mcqC$i", -size=>'40', -maxlength=>'128'}))),
                               $q->td(qq(<input type="radio" name="mca$i" value="2" $mccorrect[2]>&nbsp;Correct?))),
                        $q->Tr($q->td('&nbsp;'),
                               $q->td($q->b('Answer&nbsp;D)')),
                               $q->td($q->center($q->textfield({-name=>"mcqD$i", -size=>'40', -maxlength=>'128'}))),
                               $q->td(qq(<input type="radio" name="mca$i" value="3" $mccorrect[3]>&nbsp;Correct?))),
                        $q->Tr($q->td('&nbsp;'),
                               $q->td($q->b('Answer&nbsp;E)')),
                               $q->td($q->center($q->textfield({-name=>"mcqE$i", -size=>'40', -maxlength=>'128'}))),
                               $q->td(qq(<input type="radio" name="mca$i" value="4" $mccorrect[4]>&nbsp;Correct?))),
                        $q->Tr($q->td('&nbsp;'),
                               $q->td($q->b('Answer&nbsp;F)')),
                               $q->td($q->center($q->textfield({-name=>"mcqF$i", -size=>'40', -maxlength=>'128'}))),
                               $q->td(qq(<input type="radio" name="mca$i" value="5" $mccorrect[5]>&nbsp;Correct?))),
                        $q->Tr($q->td('&nbsp;'),
                               $q->td($q->b('All of the above')),
                               $q->td($q->center($q->checkbox({-name=>"aota$i", -value=>'yes', -label=>'Check to include'}))),
                               $q->td(qq(<input type="radio" name="mca$i" value="6" $mccorrect[6]>&nbsp;Correct?))),
                        $q->Tr($q->td('&nbsp;'),
                               $q->td($q->b('None of the above')),
                               $q->td($q->center($q->checkbox({-name=>"nota$i", -value=>'yes', -label=>'Check to include'}))),
                               $q->td(qq(<input type="radio" name="mca$i" value="7" $mccorrect[7]>&nbsp;Correct?))),
                        $q->Tr($q->td('&nbsp;'),
                               $q->td($q->b('Randomize')),
                               $q->td($q->center($q->checkbox({-name=>"rand$i", -value=>'yes', -label=>'Check to randomize options A-F'}))),
                               $q->td('&nbsp;')),
                        $q->end_table()),
                 $q->td('&nbsp;'));
  }

  print $q->end_table(),
        $q->start_table({-width=>'100%'}),
        $q->Tr($q->td({-width=>'100%'}, 'Resize table to ', $q->textfield({-name=>'mctable', -default=>$mcTableSize, -size=>'3'}), ' entries. ', $q->submit({-name=>'submit', -value=>'Resize Table'}))),
        $q->end_table(),
        $q->hr(),
        '</td>',
        $q->td('&nbsp;'),
        '</tr>';
}

print $q->end_table(),
      $q->start_table({-width=>'100%'}),
      $q->Tr($q->td({-width=>'20%'}, '&nbsp;'),
             $q->td({-width=>'40%'}, $q->submit({-name=>'submit', -value=>'Write Question to File'})),
             $q->td({-width=>'40%'}, $q->reset({-value=>'Cancel and Start Over'}))),
      $q->end_table(),
      $q->end_form(),
      $q->end_html();
