" Vim FT Plugin for editing the Win32 registry.
" Maintainer:	Colin Keith <vim@ckeith.clara.net>
" Last Change:	2002 Sept 16th
" Version:		1.0




"
" This is how we read stuff from the registry:
"
function! RegistryRead(file)
  set nowrap
perl <<EOF
  use strict;
  use vars qw($Registry $curbuf);

  eval { require "Win32/TieRegistry.pm"; };
  if($@){
    VIM::Msg("Error loading Win32::TieRegistry - $@", 'ErrorMsg');
    return 1;
  }

  Win32::TieRegistry->import();   # because we used require instead of use

  my $file = VIM::Eval('a:file'); # vim has converted this to \\ notation.
  my %rep = (HKCR =>'HKEY_CLASSES_ROOT',    HKCU=>'HKEY_CURRENT_USER',
             HKLM =>'HKEY_LOCAL_MACHINE',    HKU=>'HKEY_USERS',
             HKCC =>'CURRENT_CONFIG',   LMachine=>'HKEY_LOCAL_MACHINE',
             CUser=>'HKEY_CURRENT_USER', Classes=>'HKEY_CLASSES_ROOT',
             Users=>'HKEY_USERS',        CConfig=>'HKEY_CURRENT_CONFIG');

  $file =~ s%/%\\%g;
  $file =~ s!^registry:\\\\$_!$rep{$_}!i for(keys(%rep));
  $file =~ s%\\%/%;

  $Registry->Delimiter('/');
  my $key = $Registry->{$file};

  # Formatting:
  my $max = 9 + length($file);
  my %cp;

  sub recurse {
    my($key,$n) = @_;
    ref($key) eq 'Win32::TieRegistry' || return;

    for my $k (sort(keys(%{$key}))){
      if(ref($key->{$k})){
        my $name = "$n/$k";
        # chop($name);
        recurse($key->{$k}, $name);
        next;
      }

      $_ = "$n/$k";
      s%//*%/%g;
      $cp{$_} = $key->{$k};
      $_ = length($_);
     ($_ > $max) && ($max = $_);
    }
  }

  recurse($key, $file);

  my $i = 0;
  $max -= length($file);

  for(sort(keys(%cp))){
    my $k = $_;
    $k =~ s%^$file%%;
    $curbuf->Append($i, sprintf("%-${max}s => %s", $k, $cp{$_} ));
    ${i}++;
  }
  $curbuf->Delete(${i}+1);  # removes an ugly blank line

EOF
:endfunction



" =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
"
" This is how we write stuff from the registry:
"
function! RegistryWrite(file)
  set nowrap
perl <<EOF
#line 81
  use strict;
  use vars qw($Registry $curbuf);

  $SIG{__DIE__}  = sub { VIM::Msg($_[0], 'error'); };
  $SIG{__WARN__} = sub { VIM::Msg($_[0], 'error'); };

  eval { require "Win32/TieRegistry.pm"; };
  if($@){
    VIM::Msg("Error loading Win32::TieRegistry - $@", 'ErrorMsg');
    return 1;
  }

  Win32::TieRegistry->import();   # because we used require instead of use

  my $file = VIM::Eval('a:file'); # vim has converted this to \\ notation.
  my %rep = (HKCR =>'HKEY_CLASSES_ROOT',    HKCU=>'HKEY_CURRENT_USER',
             HKLM =>'HKEY_LOCAL_MACHINE',    HKU=>'HKEY_USERS',
             HKCC =>'CURRENT_CONFIG',   LMachine=>'HKEY_LOCAL_MACHINE',
             CUser=>'HKEY_CURRENT_USER', Classes=>'HKEY_CLASSES_ROOT',
             Users=>'HKEY_USERS',        CConfig=>'HKEY_CURRENT_CONFIG');

  $file =~ s!^registry:\\\\$_!$rep{$_}!i for(keys(%rep));
  $file =~ s%\\%/%;

  $Registry->Delimiter('/');

  my %cp;


  my $last = VIM::Eval('line("$")');
  my $c = $last;

  my(@todelete, @toadd);

  for(my $i=1; $i<=$last; $i++){
    $_ = $curbuf->Get($i);

    if(!m/^(\/.*?)([^\/]*?)\s+(=>|XX)\s*(.*?)\s*$/){
      VIM::Msg("Invalid data on line $i", 'Error');
      next;
    }

    if($3 eq 'XX'){
      delete($Registry->{"$file$1$2"});
      next;
    }

    push(@toadd, [$1, $2, $4]);
  }

  my $sort = sub { "$a->[0]/$a->[1]" cmp "$b->[0]/$b->[1]" };
  @toadd = sort $sort @toadd;

  # Build a list of all of the subkeys. I.e.  /this/is/a/test/ => xxx
  # Becomes:
  #   subkey /this/
  #   subkey /this/is/
  #   subkey /this/is/a/
  #   subkey /this/is/a/test/
  my %tarr;  # want a unique-ified list

  for(@toadd){
    my($path, $key, $val, $cnt) = (@{$_}, 0);
    while(($cnt = index($path, '/', $cnt)+1)){
      $tarr{substr($path, 0, $cnt)} = 1;
    }
  }

  # Here just create them as blank subkeys unless they exist
  for(sort(keys(%tarr))){
    ref($Registry->{"$file$_"}) && next;
    $Registry->{"$file$_"} = { '/' => '' };
  }

  # Finally we now go through and fill in the values.
  # Note the (default) value must be entered via a hash arrayref
  for(@toadd){
    my($path, $key, $val) = @{$_};
    ($key eq '') && ($val = { '/' => $val } );
    $Registry->{"$file$path$key"} = $val;
  }

  VIM::Msg('Registry Updated');

EOF
:endfunction

