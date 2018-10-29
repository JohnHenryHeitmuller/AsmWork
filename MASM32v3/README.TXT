
MASM, Pure and Simple
~~~~~~~~~~~~~~~~~~~~~

MASM32 Version 3

@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#

Please read this document, it contains information on how to set up MASM32
to run properly, considerations related to the coding design and the legal
rights of both the user and the owners of the included binary files.

@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#

----------------------------------------------------------------------------
Technical Credit & Assistance
----------------------------------------------------------------------------
Technical assistance for the MASM32 package has been made available by
Iczelion in the areas of code design and sharing the maintainance of the
WINDOWS.INC include file. < Iczelion@galaxycorp.com >


----------------------------------------------------------------------------
Introduction
----------------------------------------------------------------------------

Programmers who grew up on MASM have had a lean time over the last few
years but recently the necessary components to write and assemble 32 bit
assembler in MASM have been posted by Microsoft as free downloads.

By downloading the "platformsdk" and the "win98ddk", the programmer who
wishes to write 32 Windows assembler now has an up to date environment to
write code that is faster and smaller than many high level programmers have
ever seen before. 

Many remember assembler as a complex and tedious necessity when a high
level language failed to deliver in terms of capacity or performance yet it
has always been capable of writing full size applications in elegant and
efficient ways. MASM has the capacity to write proper modular code which
becomes a necessity as a project becomes larger. 

It has the freedom to write software ranging from the self imposed
structural approach to an absolute freestyle bag of binary with all of the
problems associated with no documentation and difficult to follow
unconditional jumps.

32 bit assembler is both clearer and simpler than the DOS and 16 bit
Windows code and is not cursed with the complexity of segment arithmetic.
You no longer have to deal with AX:DX pairs for long integers and there is
no 64k boundary imposed by the segmented structure of 16 bit software. 

The complexity of writing 32 bit Windows software is related to the
structure of Windows and the sheer range of functions in the API set. One
of the advantages of writing in assembler is that it comfortably handles
the "C" format of the Windows APIs with no difficulty. Zero terminated
strings, structures, pointers, data sizes etc... are all part of writing
assembler.

With the use of the MASM high level syntax "invoke", Windows API code can be
written very much like compiler based languages like "C" or "Pascal", the
only real difference is that you have to pick up the return value as a
separate line.

    LOCAL ReturnValue :DWORD

    invoke FunctionName, par1,par2,par3,par4
    mov ReturnValue, eax

This is in place of the less readable form,

    push par4
    push par3
    push par2
    push par1
    call FunctionName
    mov  ReturnValue, eax

There is a considerable advantage in terms of code reliability by using the
"invoke" syntax in that function calls are type checked against the
function prototypes in the include files which catches parameter mismatches.

You of course can still push the DWORD ReturnValue onto the stack manually
and use the push / call syntax if you enjoy the extra typing and assembly
errors but there is some advantage in terms of both coding speed and
reliability by automating the API function calls. This is particularly
evident when coding message loops with nested conditional testing.

The high level [.if -- .endif] syntax allows a reasonable simulation of
the "C" switch block which can be nested in the normal manner and it is
here where high level type clear coding has its real advantage. The
traditional [cmp eax, value -- je label] produces nightmares in the same
situation.

The use of the high level simulation in MASM improves the code throughput
of "hack" Windows API coding so that the more difficult areas of loop
optimisation and other performance related issues can be addressed in a tidy
and manageable way.

It needs to be understood that when using the MASM high level syntax, you
are still writing in pure assembler and you do not pay any penalty in
either size or speed by doing so. This capacity can be extended by writing
"macros" that further automate common forms of coding.

The following small macros from MASM32 demonstrates this,

      return MACRO arg
        mov eax, arg
        ret
      ENDM

  allows the programmer to exit the message proc by using the familiar "C",

    return 0

  which is expanded by the assembler into,

    mov eax, 0
    ret

Another macro used is,

      szText MACRO Name, Text:VARARG
        LOCAL lbl
          jmp lbl
            Name db Text,0
          lbl:
        ENDM

  which allows text to be directly embedded into the code.

      szText Msg1,"This is a zero terminated string"
      invoke MessageBox,hWin,ADDR Msg1,ADDR szDisplayName,MB_OK

This allows far more intuitive coding than having to go back to the
initialised .data section using,

      Msg1 db "This is a zero terminated string",0

Some may complain that this is not academically "pure" but it workes
impeccibly well in COM files as well as modern PE files and it pays no
penalty in terms of size or speed so there is little reason not to use it.

MASM32 has intentionally avoided using complex macros as they are not
initially easy to understand but there is considerable power and speed of
coding by understanding and using corectly written macros.

Another design consideration in this package is the use of generic ASM
data types. The include files generated from the platformsdk libraries by
the utility "l2inc.exe" all have DWORD data types.

The WINDOWS.INC file has had all of the data types converted to generic ASM
data types to remove the added layer of complexity in the 60 or so C++ data
types that reduce down to the generic asm BYTE, WORD, DWORD, QWORD. This
removes one of the major error sources, incorrect data types. There are a
set of conversions in WINDOWS.INC for programmers who are porting code
written with C/C++ data types into MASM32.

---------------------------------------------------------------------------
Setting up and using this package.
---------------------------------------------------------------------------

The package needs to be installed in a directory called MASM32, directly
off the root directory. This is because paths for different files are
written as relative paths so that it can be installed on any logical drive.

    drv:\
      |
      '---- MASM32

Make a directory called MASM32 and copy the file MASM32.EXE into it. Run
the file and it will expand into a set of directories, BIN / LIB / INCLUDE
etc...

To complete the setup, the Microsoft PLATFORMSDK libraries must be added to
the LIB directory. When this is done, change to the INCLUDE directory and
run the batch file BUILDINC.BAT. This will build a full set of include
files in the INCLUDE directory. Both of these steps are necessary for
MASM32 to work correctly, without libraries or include files, MASM32 will
not work.

Start the editor QEDITOR.EXE and change to the TEMPLATE directory and load
TEMPLATE.ASM. If the package has been installed in the correct directory
and the libraries have been correctly installed and the include files have
been built, selecting the "Build All" option from the TOOLS menu should
build TEMPLATE.ASM into an EXE file with no warnings or errors. 

Building the file by selecting the ASSEMBLE option from the TOOLS menu runs
ML.EXE and redirects the output to a text file that is displayed after the
file is assembled. Selecting the LINK option does the same for LINK.EXE.

The BUILD ALL option simply displays the output at the console.

The options on the PROJECT and TOOLS menus can be programmed directly from
the editor by selecting TOOLS, CHANGE EDITOR SETTINGS. This runs the INI
Editor for Quick Editor and it allow you to set up any tool you require to
build ASM files. It is to the advantage of the programmer to learn to use
the programmable menus as the limit to their number is 500 menu items which
probably cannot be fitted on the screen.

When you have finished editing the INI file, press the SAVE button and in
the editor, press F5 to refresh the menu settings in Quick Editor.

The assemble, link and build resources options on the PROJECT menu run
batch files located in the BIN directory. It is advisable to edit these
batch files and add the drive to the paths in each file. This ensures that
the tools will work on other drives on the computer.

The editor is written with F1 support for words in a HELP file. This is
determined by the first help file in the INI file after the [help] heading.
Placing the caret (text cursor) on the word and pressing F1 will bring up
the topic for the word if there is one in the help file.

The recommended help file for F1 word help is WIN32.HLP. The editor will
allow multiple help files to be added to the help menu.

---------------------------------------------------------------------------
Example Code
---------------------------------------------------------------------------

In the EXAMPLES directory are a number of directories with code examples
that have been assembled. They show in part, some of the things that can
be done in asembler. For programmers who are migrating from another
platform, there is a full commented application skeleton called GENERIC
which shows the basic structure of a win32 executable file and the minimum
things that must be done in terms of operating system requirements.

---------------------------------------------------------------------------
Licence and Users Rights
---------------------------------------------------------------------------

Some of the binaries supplied in this package are the property of the
Microsoft Corporation. Binaries from the "platformsdk" and the "win98ddk"
are used for test purposes alone for the programmer to determine the
suitability of writing in assembler. The Microsoft END USERS LICENCE
AGREEMENT states the terms and conditions under which their binary files
can be used. 

If the programmer wishes to use these binaries, they should download both
the "platformsdk" and the "win98ddk" directly from Microsoft and comply
with the conditions of licence from Microsoft. To upgrade the version of
ML.EXE, the programmer will need to download the 6.13 upgrade from
Microsoft.

The editor and accessory programs are available to any programmer to use
as they see fit without any form of cost whatsoever as long as they are
not sold or included in any commercial package. The rights extended to the
user under copyright are written in the qeditor.hlp file.

Please note that the editor & accessories retain the status of being
private property, they are not and will not be placed in the public domain.

Steve Hutchesson
Sydney
Australia < hutch@pbq.com.au >
