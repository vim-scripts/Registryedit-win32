RegistryEdit.vim v1.0
---------------------

The Registryedit.vim FTPlugin allows editing of the Windows registry from
the Vim text editor.

It uses Perl and the Win32::TieRegistry perl module by Tye McQueen to
access the Win32 registry and retreive the keys specified. You can then add
new keys, change the values of existing keys, or mark existing keys for
deletion and when you save the registry will be updated to reflect those
changes.

Why write this?
---------------

A member of the Vim mailing list wanted to know how to use Perl to extend
Vim. I replied to their message stating that it wasn't about extending Vim,
but using Perl. The two are different. Perl is a programming language, and
Vim is a text editor. The two work together very well but the problem is
that there is rarely any real use for Perl from within Vim. You may use
Perl as a parser - say to strip out all the appropriate lines of a log file
- or to process data as is common with CGI scripts, but you would never do
either of those from within Vim, even if you intended to use the output in
Vim. Scripting in Vim is useful, but limited because the output of the
script has to end up in Vim (or take the input from Vim).

But it sounded too negative to say "Uh yeah, but it has no uses", so I
wracked my brains and came up with a couple of ideas. One I suggested was
as an interface to the Win32 registry - a preprocessor I suppose it could
be termed. Of course I should have realised that the hypothetical would
have to become a reality when the original posted replied to say that they
would like to see how that was done.

 .. and thus registryedit.vim was born.

How to install it.
------------------

Prerequisites
-------------

Before we talk about the files you'll need two prerequisites - a Strength
of 18 and Dex of 15 :-) actually you'll need Vim with Perl and the key to
making this work Tye McQueen's excellent perl module for accessing the
registry Win32::TieRegistry.

To find out if you have perl compiled into Vim use:

 :version

or

 :echo has('perl')

The Win32 binaries of Vim ship with Perl with dynamic bindings - it shows
up in "version" as perl/dyn. If you have this then Vim is dynamically
linked to Perl rather than statically linked. This is good because it makes
Vim smaller and if you never (want to) use Perl you don't suffer the bloat.
(Sadly it doesn't allow you to upgrade your version of Perl externally
because it still tries to link with perl56.dll, but...) If you don't have
Perl installed then panic ye not as Frankie Howard would say. Its really
easy to install, just hop over to http://www.activestate.com and download
ActiveState Perl (ASP). If you're adventurous you can download the source
and compile it yourself just using GNU utils (free - no paying Microbunny
for VC++ just to get a compiler). You don't even need Cygwin, although that
is also another source for it. (Yes I have done it myself for perl 5.8.0,
no I won't help you do it, I'm too busy working at the moment to have a
social life, let alone spend more time on the computer :-)

Once you are okay with Perl, you need to check for the Win32::TieRegistry.
If you have ActiveState Perl then use PPM (ppm3-bin.exe or just ppm3)

  install libwin32

This will install Win32::TieRegistry. Note that you don't want
Win32API::Registry as it has been superceeded by Win32::TieRegistry.



RegistryEdit files to install.
------------------------------

Included in the zip are four files. This readme file, registryedit.vim
(ooh, wonder what that is) and filetypes.vim. We'll start with
filetypes.vim.

 * filetypes.vim
   This is an example of how to configure vim to recognise when you are
   trying to access the registry. I put this into my filetypes.vim in

      vimfiles\filetypes.vim

   This way it gets sourced whenever Vim looks for a filetype. As you can
   see, the autocmds catch the pattern

       registry://*

   And when triggered source the registryedit.vim file to load the
   functions for reading and writing to the registry. Of course don't just
   overwrite this file, please append the code if you already have a
   filetypes.vim.

 * registryedit.vim
   Place this file into your local ftplugins directory:

      vimfiles\ftplugin\registryedit.vim

   To be honest I wasn't sure where to put this file. It isn't exactly a
   plugin for a particular filetype, but it is for a particular way of
   accessing a "file". Besides which, I didn't want these functions being
   loaded from a script in the plugin directory because they'll be rarely
   used and it will just bloat Vim uncessessarily. Since there's no
   filetype for "registryedit", it is as easy for me to steal the name and
   use it as I want.

 * registryedit.txt

   This is the documentation for the module. You can add it to your local
   documentation by placing the file into

      vimfiles\doc\registryedit.txt

   and then using the {:helptags} command as described in {add-local-help}:

      :helptags vimfiles\doc

   This will generate a tags file for this help document (and any others)
   so you will have the man pages available on demand.


How to use it.
--------------

To use access it simply supply a URL style filename to vim when opening or
editing a document:

 gvim registry://HKCR/.vim

 :e registry://HKCR/.txt

The filename consists of 3 parts, the URL style registry:// (which is the
pattern that the autocmds match on), the HIVE name, and the key within the
Hive. The Hive is one of the 5 main branches of the Windows registry:

  HKEY_CLASSES_ROOT
  HKEY_LOCAL_MACHINE
  HKEY_CURRENT_USER
  HKEY_USERS
  HKEY_CURRENT_CONFIG

(There is also a HKEY_DYNAMIC_DATA in some verisons of Windows IIRC)

You cannot skip the Hive name for safety purposes. Basically I don't want you
calling me up going "I deleted /" and it nuked your entire Hive. It would not
be a pretty effect (well, unless you like Blue :-). The names can be truncated
in several ways. Any of the above are valid, plus just the acronyms (HKCR,
HKLM, etc) and some lazy Windows programmer's notations CRoot, LMachine,
CUser, etc.

After the hive you specify the key you want to examine. You _can_ specify
nothing. I.e.

  gvim registry://HKCR/

But it is *really stupid* all that happened to me was my computer swapped lots
before I got bored and killed it. Be clever kids, say no, specify a key. I.e.

  gvim registry://HKCR/.vim

When you specify a properly formatted URL, the function RegistryRead() will
connect Perl to the registry and extract the information. If any keys are
found to have subkeys, they are interogated too. Thus you might see something
like:


   /               =>  vim_auto_file
   /Content Type   =>  text/plain
   .
   .

That's your registry. That example isn't very cool so lets try:

  gvim registry://HKCR/AcroExch.Document

  /                       => Adobe Acrobat Document
  /AcrobatVersion/        => 5.0
  /BrowseInPlace          => Adobe Acrobat Document
  /CLSID/                 => {B801CA65-A1FC-11D0-85AD-444553540000}
  /DefaultIcon/           => C:\Program Files\Adobe\Acrobat 5.0\Reader\AcroRd32.exe,1
  /shell/open/command/    => "C:\Program Files\Adobe\Acrobat 5.0\Reader\AcroRd32.exe" "%1"
  /shell/print/command/   => "C:\Program Files\Adobe\Acrobat 5.0\Reader\AcroRd32.exe" /p /h "%1"
  /shell/printto/command/ => "C:\Program Files\Adobe\Acrobat 5.0\Reader\AcroRd32.exe" /t "%1" "%2" "%3" "%4"

(A few entries have been removed because of the long lines)

Editing entries
---------------

As you can see here we now have all of the information from that key in the
registry. But what can you do with it? Well, say you didn't like the first
icon in the AcroRd32.exe and you wanted your Adobe documents to all use the
second icon, you'd change the line to show:

  /DefaultIcon/  => C:\Program Files\Adobe\Acrobat 5.0\Reader\AcroRd32.exe,2


This is the same as the Regedit file entry:

 [HKEY_CLASSES_ROOT/AcroExch.Document/DefaultIcon]
 @="C:\\Program Files\\Adobe\\Acrobat 5.0\\Reader\\AcroRd32.exe,1"

Adding entries
--------------

You can also add a totally new entry into the key in which you're editing by
simply adding a new line in the same format. For example:

 /shell/edit/command/   => "C:\vim\vim61\gvim.exe" -b "%1"

When you save this {RegistryEdit} will actually understand that you mean:

 Create the keys

  * HKEY_CLASSES_ROOT/AcroExch.Document/shell/
  * HKEY_CLASSES_ROOT/AcroExch.Document/shell/edit/
  * HKEY_CLASSES_ROOT/AcroExch.Document/shell/edit/command/

It will set all of the (default) values to "not set" ('') and then set the
value for the default key to be gvim. It also doesn't matter what order you
specify the data in as it will be sorted before entry.

-----> BE WARNED: <-----

Vim is a text editor, it does not do binary data and text data in
the same document (very well) so currently RegistryEdit offers no support for
the different data types supported by the registry. Everything is inserted as a
String value. If the data you extract has a binary component, do not save with
that line still in the file or it will be written back as a string component,
not a binary component.


Removing entries
----------------

If you decided that you didn't like the printto command being set, then you
could remove it using:

  /shell/printto/command/ XX 

The trailing text (and white space) is optional when deleting as all the
program needs to know about is the registry key.


CHANGES
-------

 v0.5
 * Connecting to the registry for reading successfully

 v0.6
 * Fixed formmating and sorting problems with data read from the registry.

 v0.7
 * Connecting to the registry for writing.

 v0.8
 * Rewrite of the saving algorithm

 v0.9
 * Discovered sort's don't work under Vim properly and rewrote the save
   algorithm because it wasn't working in all cases. Rewrote several times,
   finally settling on extracing the path, key and value then iterating over
   the path part using index() and storing the components into a hash. This
   prevents the need to keep requesting if / exists as a key or not, each
   part of the path is asked for just once.

 v1.0
 * Documentation, formatting, released.



Help
----

Hopefully this document will clarify some of the problems I caused by being
clueless about where to place files in Vim. Contact the author if you have
any problems or questions (or suggestions, or just want to offer exotic
jobs on wealthy tropical islands ... :)

Author
------
 Colin Keith <vim@ckeith.clara.net>

 vim:tw=78:ts=8:ft=help:norl:
