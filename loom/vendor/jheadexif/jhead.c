//--------------------------------------------------------------------------
// Program to pull the information out of various types of EXIF digital 
// camera files and show it in a reasonably consistent way
//
// Version 2.97
//
// Compiling under Windows:  
//   Make sure you have Microsoft's compiler on the path, then run make.bat
//
// Dec 1999 - Jan 2013
//
// by Matthias Wandel   www.sentex.net/~mwandel
//--------------------------------------------------------------------------
#ifdef _WIN32
    #include <io.h>
#endif

#include "jhead.h"

#include <sys/stat.h>

#define JHEAD_VERSION "2.97"

// This #define turns on features that are too very specific to 
// how I organize my photos.  Best to ignore everything inside #ifdef MATTHIAS
//#define MATTHIAS


// Bitmasks for DoModify:
#define MODIFY_ANY  1
#define READ_ANY    2
#define JPEGS_ONLY  4
#define MODIFY_JPEG 5
#define READ_JPEG   6
static int DoModify  = FALSE;


static int FilesMatched;
static int FileSequence;

static const char * CurrentFile;

static const char * progname;   // program name for error messages

//--------------------------------------------------------------------------
// Command line options flags
static int TrimExif = FALSE;        // Cut off exif beyond interesting data.
static int RenameToDate = 0;        // 1=rename, 2=rename all.
#ifdef _WIN32
static int RenameAssociatedFiles = FALSE;
#endif
static char * strftime_args = NULL; // Format for new file name.
static int Exif2FileTime  = FALSE;
       int ShowTags     = FALSE;    // Do not show raw by default.
static int Quiet        = FALSE;    // Be quiet on success (like unix programs)
       int DumpExifMap  = FALSE;
static int ShowConcise  = FALSE;
static int CreateExifSection = FALSE;
static char * ApplyCommand = NULL;  // Apply this command to all images.
static char * FilterModel = NULL;
static int    ExifOnly    = FALSE;
static int    PortraitOnly = FALSE;
static time_t ExifTimeAdjust = 0;   // Timezone adjust
static time_t ExifTimeSet = 0;      // Set exif time to a value.
static char DateSet[11];
static unsigned DateSetChars = 0;
static unsigned FileTimeToExif = FALSE;

static int DeleteComments = FALSE;
static int DeleteExif = FALSE;
static int DeleteIptc = FALSE;
static int DeleteXmp = FALSE;
static int DeleteUnknown = FALSE;
static char * ThumbSaveName = NULL; // If not NULL, use this string to make up
                                    // the filename to store the thumbnail to.

static char * ThumbInsertName = NULL; // If not NULL, use this string to make up
                                    // the filename to retrieve the thumbnail from.

static int RegenThumbnail = FALSE;

static char * ExifXferScrFile = NULL;// Extract Exif header from this file, and
                                    // put it into the Jpegs processed.

static int EditComment = FALSE;     // Invoke an editor for editing the comment
static int SupressNonFatalErrors = FALSE; // Wether or not to pint warnings on recoverable errors

static char * CommentSavefileName = NULL; // Save comment to this file.
static char * CommentInsertfileName = NULL; // Insert comment from this file.
static char * CommentInsertLiteral = NULL;  // Insert this comment (from command line)

static int AutoRotate = FALSE;
static int ZeroRotateTagOnly = FALSE;

static int ShowFileInfo = TRUE;     // Indicates to show standard file info
                                    // (file name, file size, file date)


#ifdef MATTHIAS
    // This #ifdef to take out less than elegant stuff for editing
    // the comments in a JPEG.  The programs rdjpgcom and wrjpgcom
    // included with Linux distributions do a better job.

    static char * AddComment = NULL; // Add this tag.
    static char * RemComment = NULL; // Remove this tag
    static int AutoResize = FALSE;
#endif // MATTHIAS

//--------------------------------------------------------------------------
// Error exit handler
//--------------------------------------------------------------------------
void ErrFatal(const char * msg)
{
    fprintf(stderr,"\nError : %s\n", msg);
    if (CurrentFile) fprintf(stderr,"in file '%s'\n",CurrentFile);
    exit(EXIT_FAILURE);
} 

//--------------------------------------------------------------------------
// Report non fatal errors.  Now that microsoft.net modifies exif headers,
// there's corrupted ones, and there could be more in the future.
//--------------------------------------------------------------------------
void ErrNonfatal(const char * msg, int a1, int a2)
{
    if (SupressNonFatalErrors) return;

    fprintf(stderr,"\nNonfatal Error : ");
    if (CurrentFile) fprintf(stderr,"'%s' ",CurrentFile);
    fprintf(stderr, msg, a1, a2);
    fprintf(stderr, "\n");
} 


//--------------------------------------------------------------------------
// Invoke an editor for editing a string.
//--------------------------------------------------------------------------
static int FileEditComment(char * TempFileName, char * Comment, int CommentSize)
{
    FILE * file;
    int a;
    char QuotedPath[PATH_MAX+10];

    file = fopen(TempFileName, "w");
    if (file == NULL){
        fprintf(stderr, "Can't create file '%s'\n",TempFileName);
        ErrFatal("could not create temporary file");
    }
    fwrite(Comment, CommentSize, 1, file);

    fclose(file);

    fflush(stdout); // So logs are contiguous.

    {
        char * Editor;
        Editor = getenv("EDITOR");
        if (Editor == NULL){
#ifdef _WIN32
            Editor = "notepad";
#else
            Editor = "vi";
#endif
        }
        if (strlen(Editor) > PATH_MAX) ErrFatal("env too long");

        sprintf(QuotedPath, "%s \"%s\"",Editor, TempFileName);
        a = system(QuotedPath);
    }

    if (a != 0){
        perror("Editor failed to launch");
        exit(-1);
    }

    file = fopen(TempFileName, "r");
    if (file == NULL){
        ErrFatal("could not open temp file for read");
    }

    // Read the file back in.
    CommentSize = fread(Comment, 1, 999, file);

    fclose(file);

    unlink(TempFileName);

    return CommentSize;
}

#ifdef MATTHIAS
//--------------------------------------------------------------------------
// Modify one of the lines in the comment field.
// This very specific to the photo album program stuff.
//--------------------------------------------------------------------------
static char KnownTags[][10] = {"date", "desc","scan_date","author",
                               "keyword","videograb",
                               "show_raw","panorama","titlepix",""};

static int ModifyDescriptComment(char * OutComment, char * SrcComment)
{
    char Line[500];
    int Len;
    int a,i;
    unsigned l;
    int HasScandate = FALSE;
    int TagExists = FALSE;
    int Modified = FALSE;
    Len = 0;

    OutComment[0] = 0;


    for (i=0;;i++){
        if (SrcComment[i] == '\r' || SrcComment[i] == '\n' || SrcComment[i] == 0 || Len >= 199){
            // Process the line.
            if (Len > 0){
                Line[Len] = 0;
                //printf("Line: '%s'\n",Line);
                for (a=0;;a++){
                    l = strlen(KnownTags[a]);
                    if (!l){
                        // Unknown tag.  Discard it.
                        printf("Error: Unknown tag '%s'\n", Line); // Deletes the tag.
                        Modified = TRUE;
                        break;
                    }
                    if (memcmp(Line, KnownTags[a], l) == 0){
                        if (Line[l] == ' ' || Line[l] == '=' || Line[l] == 0){
                            // Its a good tag.
                            if (Line[l] == ' ') Line[l] = '='; // Use equal sign for clarity.
                            if (a == 2) break; // Delete 'orig_path' tag.
                            if (a == 3) HasScandate = TRUE;
                            if (RemComment){
                                if (strlen(RemComment) == l){
                                    if (!memcmp(Line, RemComment, l)){
                                        Modified = TRUE;
                                        break;
                                    }
                                }
                            }
                            if (AddComment){
                                // Overwrite old comment of same tag with new one.
                                if (!memcmp(Line, AddComment, l+1)){
                                    TagExists = TRUE;
                                    strncpy(Line, AddComment, sizeof(Line));
                                    Modified = TRUE;
                                }
                            }
                            strncat(OutComment, Line, MAX_COMMENT_SIZE-5-strlen(OutComment));
                            strcat(OutComment, "\n");
                            break;
                        }
                    }
                }
            }
            Line[Len = 0] = 0;
            if (SrcComment[i] == 0) break;
        }else{
            Line[Len++] = SrcComment[i];
        }
    }

    if (AddComment && TagExists == FALSE){
        strncat(OutComment, AddComment, MAX_COMMENT_SIZE-5-strlen(OutComment));
        strcat(OutComment, "\n");
        Modified = TRUE;
    }

    if (!HasScandate && !ImageInfo.DateTime[0]){
        // Scan date is not in the file yet, and it doesn't have one built in.  Add it.
        char Temp[40];
        sprintf(Temp, "scan_date=%s", ctime(&ImageInfo.FileDateTime));
        strncat(OutComment, Temp, MAX_COMMENT_SIZE-5-strlen(OutComment));
        Modified = TRUE;
    }
    return Modified;
}
//--------------------------------------------------------------------------
// Automatic make smaller command stuff
//--------------------------------------------------------------------------
static int AutoResizeCmdStuff(void)
{
    static char CommandString[PATH_MAX+1];
    double scale;
    float TargetSize = 1600;

    ApplyCommand = CommandString;

    scale = TargetSize / ImageInfo.Width;
    if (TargetSize / ImageInfo.Height > scale) scale = TargetSize  / ImageInfo.Width;

    if (scale > 0.8){
        printf("not resizing %dx%x '%s'\n",ImageInfo.Height, ImageInfo.Width, ImageInfo.FileName);
        return FALSE;
    }

    if (scale < 0.4) scale = 0.4; // Don't scale down by too much.

    sprintf(CommandString, "mogrify -geometry %dx%d -quality 80 &i",(int)(ImageInfo.Width*scale), (int)(ImageInfo.Height*scale));
    return TRUE;
}


#endif // MATTHIAS


//--------------------------------------------------------------------------
// Escape an argument such that it is interpreted literally by the shell
// (returns the number of written characters)
//--------------------------------------------------------------------------
static int shellescape(char* to, const char* from)
{
    int i, j;
    i = j = 0;

    // Enclosing characters in double quotes preserves the literal value of
    // all characters within the quotes, with the exception of $, `, and \.
    to[j++] = '"';
    while(from[i])
    {
#ifdef _WIN32
        // Under WIN32, there isn't really anything dangerous you can do with 
        // escape characters, plus windows users aren't as sercurity paranoid.
        // Hence, no need to do fancy escaping.
        to[j++] = from[i++];
#else
        switch(from[i]) {
            case '"':
            case '$':
            case '`':
            case '\\':
                to[j++] = '\\';
                // Fallthru...
            default:
                to[j++] = from[i++];
        }
#endif 
        if (j >= PATH_MAX) ErrFatal("max path exceeded");
    }
    to[j++] = '"';
    return j;
}


//--------------------------------------------------------------------------
// Apply the specified command to the JPEG file.
//--------------------------------------------------------------------------
static void DoCommand(const char * FileName, int ShowIt)
{
    int a,e;
    char ExecString[PATH_MAX*3];
    char TempName[PATH_MAX+10];
    int TempUsed = FALSE;

    e = 0;

    // Generate an unused temporary file name in the destination directory
    // (a is the number of characters to copy from FileName)
    a = strlen(FileName)-1;
    while(a > 0 && FileName[a-1] != SLASH) a--;
    memcpy(TempName, FileName, a);
    strcpy(TempName+a, "XXXXXX");

    // Note: Compiler will warn about mkstemp.  but I need a filename, not a file.
    // I could just then get the fiel name from what mkstemp made, and pass that
    // to the executable, but that would make for the exact same vulnerability
    // as mktemp - that is, that between getting the random name, and making the file
    // some other program could snatch that exact same name!
    // also, not all pltforms support mkstemp.
    mktemp(TempName);


    if(!TempName[0]) {
        ErrFatal("Cannot find available temporary file name");
    }


    // Build the exec string.  &i and &o in the exec string get replaced by input and output files.
    for (a=0;;a++){
        if (ApplyCommand[a] == '&'){
            if (ApplyCommand[a+1] == 'i'){
                // Input file.
                e += shellescape(ExecString+e, FileName);
                a += 1;
                continue;
            }
            if (ApplyCommand[a+1] == 'o'){
                // Needs an output file distinct from the input file.
                e += shellescape(ExecString+e, TempName);
                a += 1;
                TempUsed = TRUE;
                continue;
            }
        }
        ExecString[e++] = ApplyCommand[a];
        if (ApplyCommand[a] == 0) break;
    }

    if (ShowIt) printf("Cmd:%s\n",ExecString);

    errno = 0;
    a = system(ExecString);

    if (a || errno){
        // A command can however fail without errno getting set or system returning an error.
        if (errno) perror("system");
        ErrFatal("Problem executing specified command");
    }

    if (TempUsed){
        // Don't delete original file until we know a new one was created by the command.
        struct stat dummy;
        if (stat(TempName, &dummy) == 0){
            unlink(FileName);
            rename(TempName, FileName);
        }else{
            ErrFatal("specified command did not produce expected output file");
        }
    }
}

//--------------------------------------------------------------------------
// check if this file should be skipped based on contents.
//--------------------------------------------------------------------------
static int CheckFileSkip(void)
{
    // I sometimes add code here to only process images based on certain
    // criteria - for example, only to convert non progressive Jpegs to progressives, etc..

    if (FilterModel){
        // Filtering processing by camera model.
        // This feature is useful when pictures from multiple cameras are colated, 
        // the its found that one of the cameras has the time set incorrectly.
        if (strstr(ImageInfo.CameraModel, FilterModel) == NULL){
            // Skip.
            return TRUE;
        }
    }

    if (ExifOnly){
        // Filtering by EXIF only.  Skip all files that have no Exif.
        if (FindSection(M_EXIF) == NULL){
            return TRUE;
        }
    }

    if (PortraitOnly == 1){
        if (ImageInfo.Width > ImageInfo.Height) return TRUE;
    }

    if (PortraitOnly == -1){
        if (ImageInfo.Width < ImageInfo.Height) return TRUE;
    }

    return FALSE;
}

//--------------------------------------------------------------------------
// Subsititute original name for '&i' if present in specified name.
// This to allow specifying relative names when manipulating multiple files.
//--------------------------------------------------------------------------
static void RelativeName(char * OutFileName, const char * NamePattern, const char * OrigName)
{
    // If the filename contains substring "&i", then substitute the 
    // filename for that.  This gives flexibility in terms of processing
    // multiple files at a time.
    char * Subst;
    Subst = strstr(NamePattern, "&i");
    if (Subst){
        strncpy(OutFileName, NamePattern, Subst-NamePattern);
        OutFileName[Subst-NamePattern] = 0;
        strncat(OutFileName, OrigName, PATH_MAX);
        strncat(OutFileName, Subst+2, PATH_MAX);
    }else{
        strncpy(OutFileName, NamePattern, PATH_MAX); 
    }
}


#ifdef _WIN32
//--------------------------------------------------------------------------
// Rename associated files
//--------------------------------------------------------------------------
void RenameAssociated(const char * FileName, char * NewBaseName)
{
    int a;
    int PathLen;
    int ExtPos;
    char FilePattern[_MAX_PATH+1];
    char NewName[_MAX_PATH+1];
    struct _finddata_t finddata;
    long find_handle;

    for(ExtPos = strlen(FileName);FileName[ExtPos-1] != '.';){
        if (--ExtPos == 0) return; // No extension!
    }

    memcpy(FilePattern, FileName, ExtPos);
    FilePattern[ExtPos] = '*';
    FilePattern[ExtPos+1] = '\0';

    for(PathLen = strlen(FileName);FileName[PathLen-1] != SLASH;){
        if (--PathLen == 0) break;
    }

    find_handle = _findfirst(FilePattern, &finddata);

    for (;;){
        if (find_handle == -1) break;

        // Eliminate the obvious patterns.
        if (!memcmp(finddata.name, ".",2)) goto next_file;
        if (!memcmp(finddata.name, "..",3)) goto next_file;
        if (finddata.attrib & _A_SUBDIR) goto next_file;

        strncpy(FilePattern+PathLen, finddata.name, PATH_MAX-PathLen); // full name with path

        strcpy(NewName, NewBaseName);
        for(a = strlen(finddata.name);finddata.name[a] != '.';){
            if (--a == 0) goto next_file;
        }
        strncat(NewName, finddata.name+a, _MAX_PATH-strlen(NewName)); // add extension to new name

        if (rename(FilePattern, NewName) == 0){
            if (!Quiet){
                printf("%s --> %s\n",FilePattern, NewName);
            }
        }

        next_file:
        if (_findnext(find_handle, &finddata) != 0) break;
    }
    _findclose(find_handle);
}
#endif

//--------------------------------------------------------------------------
// Rotate the image and its thumbnail
//--------------------------------------------------------------------------
static int DoAutoRotate(const char * FileName)
{
    if (ImageInfo.Orientation >= 2 && ImageInfo.Orientation <= 8){
        const char * Argument;
        Argument = ClearOrientation();

        if (!ZeroRotateTagOnly){
            char RotateCommand[PATH_MAX*2+50];
            if (Argument == NULL){
                ErrFatal("Orientation screwup");
            }

            sprintf(RotateCommand, "jpegtran -trim -%s -outfile &o &i", Argument);
            ApplyCommand = RotateCommand;
            DoCommand(FileName, FALSE);
            ApplyCommand = NULL;

            // Now rotate the thumbnail, if there is one.
            if (ImageInfo.ThumbnailOffset && 
                ImageInfo.ThumbnailSize && 
                ImageInfo.ThumbnailAtEnd){
                // Must have a thumbnail that exists and is modifieable.

                char ThumbTempName_in[PATH_MAX+5];
                char ThumbTempName_out[PATH_MAX+5];

                strcpy(ThumbTempName_in, FileName);
                strcat(ThumbTempName_in, ".thi");
                strcpy(ThumbTempName_out, FileName);
                strcat(ThumbTempName_out, ".tho");
                SaveThumbnail(ThumbTempName_in);
                sprintf(RotateCommand,"jpegtran -trim -%s -outfile \"%s\" \"%s\"",
                    Argument, ThumbTempName_out, ThumbTempName_in);

                if (system(RotateCommand) == 0){
                    // Put the thumbnail back in the header
                    ReplaceThumbnail(ThumbTempName_out);
                }

                unlink(ThumbTempName_in);
                unlink(ThumbTempName_out);
            }
        }
        return TRUE;
    }
    return FALSE;
}

//--------------------------------------------------------------------------
// Regenerate the thumbnail using mogrify
//--------------------------------------------------------------------------
static int RegenerateThumbnail(const char * FileName)
{
    char ThumbnailGenCommand[PATH_MAX*2+50];
    if (ImageInfo.ThumbnailOffset == 0 || ImageInfo.ThumbnailAtEnd == FALSE){
        // There is no thumbnail, or the thumbnail is not at the end.
        return FALSE;
    }

    sprintf(ThumbnailGenCommand, "mogrify -thumbnail %dx%d \"%s\"", 
        RegenThumbnail, RegenThumbnail, FileName);

    if (system(ThumbnailGenCommand) == 0){
        // Put the thumbnail back in the header
        return ReplaceThumbnail(FileName);
    }else{
        ErrFatal("Unable to run 'mogrify' command");
        return FALSE;
    }
}

//--------------------------------------------------------------------------
// Set file time as exif time.
//--------------------------------------------------------------------------
void FileTimeAsString(char * TimeStr)
{
    struct tm ts;
    ts = *localtime(&ImageInfo.FileDateTime);
    strftime(TimeStr, 20, "%Y:%m:%d %H:%M:%S", &ts);
}

//--------------------------------------------------------------------------
// complain about bad state of the command line.
//--------------------------------------------------------------------------
static void Usage (void)
{
    printf("Jhead is a program for manipulating settings and thumbnails in Exif jpeg headers\n"
           "used by most Digital Cameras.  v"JHEAD_VERSION" Matthias Wandel, Jan 30 2013.\n"
           "http://www.sentex.net/~mwandel/jhead\n"
           "\n");

    printf("Usage: %s [options] files\n", progname);
    printf("Where:\n"
           " files       path/filenames with or without wildcards\n"

           "[options] are:\n"
           "\nGENERAL METADATA:\n"
           "  -te <name> Transfer exif header from another image file <name>\n"
           "             Uses same name mangling as '-st' option\n"
           "  -dc        Delete comment field (as left by progs like Photoshop & Compupic)\n"
           "  -de        Strip Exif section (smaller JPEG file, but lose digicam info)\n"
           "  -di        Delete IPTC section (from Photoshop, or Picasa)\n"
           "  -dx        Deletex XMP section\n"
           "  -du        Delete non image sections except for Exif and comment sections\n"
           "  -purejpg   Strip all unnecessary data from jpeg (combines -dc -de and -du)\n"
           "  -mkexif    Create new minimal exif section (overwrites pre-existing exif)\n"
           "  -ce        Edit comment field.  Uses environment variable 'editor' to\n"
           "             determine which editor to use.  If editor not set, uses VI\n"
           "             under Unix and notepad with windows\n"
           "  -cs <name> Save comment section to a file\n"
           "  -ci <name> Insert comment section from a file.  -cs and -ci use same naming\n"
           "             scheme as used by the -st option\n"
           "  -cl string Insert literal comment string\n"

           "\nDATE / TIME MANIPULATION:\n"
           "  -ft        Set file modification time to Exif time\n"
           "  -dsft      Set Exif time to file modification time\n"
           "  -n[format-string]\n"
           "             Rename files according to date.  Uses exif date if present, file\n"
           "             date otherwise.  If the optional format-string is not supplied,\n"
           "             the format is mmdd-hhmmss.  If a format-string is given, it is\n"
           "             is passed to the 'strftime' function for formatting\n"
           "             %%d Day of month    %%H Hour (24-hour)\n"
           "             %%m Month number    %%M Minute    %%S Second\n"
           "             %%y Year (2 digit 00 - 99)        %%Y Year (4 digit 1980-2036)\n"
           "             For more arguments, look up the 'strftime' function.\n"
           "             In addition to strftime format codes:\n"
           "             '%%f' as part of the string will include the original file name\n"
           "             '%%i' will include a sequence number, starting from 1. You can\n"
           "             You can specify '%%03i' for example to get leading zeros.\n"
           "             This feature is useful for ordering files from multiple digicams to\n"
           "             sequence of taking.  Only renames files whose names are mostly\n"
           "             numerical (as assigned by digicam)\n"
           "             The '.jpg' is automatically added to the end of the name.  If the\n"
           "             destination name already exists, a letter or digit is added to \n"
           "             the end of the name to make it unique.\n"
           "             The new name may include a path as part of the name.  If this path\n"
           "             does not exist, it will be created\n"
           "  -a         (Windows only) Rename files with same name but different extension\n"
           "             Use together with -n to rename .AVI files from exif in .THM files\n"
           "             for example\n"
           "  -ta<+|->h[:mm[:ss]]\n"
           "             Adjust time by h:mm forwards or backwards.  Useful when having\n"
           "             taken pictures with the wrong time set on the camera, such as when\n"
           "             traveling across time zones or DST changes. Dates can be adjusted\n"
           "             by offsetting by 24 hours or more.  For large date adjustments,\n"
           "             use the -da option\n"
           "  -da<date>-<date>\n"
           "             Adjust date by large amounts.  This is used to fix photos from\n"
           "             cameras where the date got set back to the default camera date\n"
           "             by accident or battery removal.\n"
           "             To deal with different months and years having different numbers of\n"
           "             days, a simple date-month-year offset would result in unexpected\n"
           "             results.  Instead, the difference is specified as desired date\n"
           "             minus original date.  Date is specified as yyyy:mm:dd or as date\n"
           "             and time in the format yyyy:mm:dd/hh:mm:ss\n"
           "  -ts<time>  Set the Exif internal time to <time>.  <time> is in the format\n"
           "             yyyy:mm:dd-hh:mm:ss\n"
           "  -ds<date>  Set the Exif internal date.  <date> is in the format YYYY:MM:DD\n"
           "             or YYYY:MM or YYYY\n"

           "\nTHUMBNAIL MANIPULATION:\n"
           "  -dt        Remove exif integral thumbnails.   Typically trims 10k\n"
           "  -st <name> Save Exif thumbnail, if there is one, in file <name>\n"
           "             If output file name contains the substring \"&i\" then the\n"
           "             image file name is substitute for the &i.  Note that quotes around\n"
           "             the argument are required for the '&' to be passed to the program.\n"
#ifndef _WIN32
           "             An output name of '-' causes thumbnail to be written to stdout\n"
#endif
           "  -rt <name> Replace Exif thumbnail.  Can only be done with headers that\n"
           "             already contain a thumbnail.\n"
           "  -rgt[size] Regnerate exif thumbnail.  Only works if image already\n"
           "             contains a thumbail.  size specifies maximum height or width of\n"
           "             thumbnail.  Relies on 'mogrify' programs to be on path\n"

           "\nROTATION TAG MANIPULATION:\n"
           "  -autorot   Invoke jpegtran to rotate images according to Exif orientation tag\n"
           "             Note: Windows users must get jpegtran for this to work\n"
           "  -norot     Zero out the rotation tag.  This to avoid some browsers from\n" 
           "             rotating the image again after you rotated it but neglected to\n"
           "             clear the rotation tag\n"

           "\nOUTPUT VERBOSITY CONTROL:\n"
           "  -h         help (this text)\n"
           "  -v         even more verbose output\n"
           "  -q         Quiet (no messages on success, like Unix)\n"
           "  -V         Show jhead version\n"
           "  -exifmap   Dump header bytes, annotate.  Pipe thru sort for better viewing\n"
           "  -se        Supress error messages relating to corrupt exif header structure\n"
           "  -c         concise output\n"
           "  -nofinfo   Don't show file info (name/size/date)\n"

           "\nFILE MATCHING AND SELECTION:\n"
           "  -model model\n"
           "             Only process files from digicam containing model substring in\n"
           "             camera model description\n"
           "  -exonly    Skip all files that don't have an exif header (skip all jpegs that\n"
           "             were not created by digicam)\n"
           "  -cmd command\n"
           "             Apply 'command' to every file, then re-insert exif and command\n"
           "             sections into the image. &i will be substituted for the input file\n"
           "             name, and &o (if &o is used). Use quotes around the command string\n"
           "             This is most useful in conjunction with the free ImageMagick tool. \n"
           "             For example, with my Canon S100, which suboptimally compresses\n"
           "             jpegs I can specify\n"
           "                jhead -cmd \"mogrify -quality 80 &i\" *.jpg\n"
           "             to re-compress a lot of images using ImageMagick to half the size,\n" 
           "             and no visible loss of quality while keeping the exif header\n"
           "             Another invocation I like to use is jpegtran (hard to find for\n"
           "             windows).  I type:\n"
           "                jhead -cmd \"jpegtran -progressive &i &o\" *.jpg\n"
           "             to convert jpegs to progressive jpegs (Unix jpegtran syntax\n"
           "             differs slightly)\n"
           "  -orp       Only operate on 'portrait' aspect ratio images\n"
           "  -orl       Only operate on 'landscape' aspect ratio images\n"
#ifdef _WIN32
           "  -r         No longer supported.  Use the ** wildcard to recurse directories\n"
           "             with instead.\n"
           "             examples:\n"
           "                 jhead **/*.jpg\n"
           "                 jhead \"c:\\my photos\\**\\*.jpg\"\n"
#endif


#ifdef MATTHIAS
           "\n"
           "  -cr        Remove comment tag (my way)\n"
           "  -ca        Add comment tag (my way)\n"
           "  -ar        Auto resize to fit in 1024x1024, but never less than half\n"
#endif //MATTHIAS


           );

    exit(EXIT_FAILURE);
}


//--------------------------------------------------------------------------
// Parse specified date or date+time from command line.
//--------------------------------------------------------------------------
static time_t ParseCmdDate(char * DateSpecified)
{
    int a;
    struct tm tm;
    time_t UnixTime;

    tm.tm_wday = -1;
    tm.tm_hour = tm.tm_min = tm.tm_sec = 0;

    a = sscanf(DateSpecified, "%d:%d:%d/%d:%d:%d",
            &tm.tm_year, &tm.tm_mon, &tm.tm_mday,
            &tm.tm_hour, &tm.tm_min, &tm.tm_sec);

    if (a != 3 && a < 5){
        // Date must be YYYY:MM:DD, YYYY:MM:DD+HH:MM
        // or YYYY:MM:DD+HH:MM:SS
        ErrFatal("Could not parse specified date");
    }
    tm.tm_isdst = -1;  
    tm.tm_mon -= 1;      // Adjust for unix zero-based months 
    tm.tm_year -= 1900;  // Adjust for year starting at 1900 

    UnixTime = mktime(&tm);
    if (UnixTime == -1){
        ErrFatal("Specified time is invalid or out of range");
    }
    
    return UnixTime;    
}

//--------------------------------------------------------------------------
// The main program.
//--------------------------------------------------------------------------
/*
int main (int argc, char **argv)
{
    int argn;
    char * arg;
    progname = argv[0];

    for (argn=1;argn<argc;argn++){
        arg = argv[argn];
        if (arg[0] != '-') break; // Filenames from here on.

    // General metadata options:
        if (!strcmp(arg,"-te")){
            ExifXferScrFile = argv[++argn];
            DoModify |= MODIFY_JPEG;
        }else if (!strcmp(arg,"-dc")){
            DeleteComments = TRUE;
            DoModify |= MODIFY_JPEG;
        }else if (!strcmp(arg,"-de")){
            DeleteExif = TRUE;
            DoModify |= MODIFY_JPEG;
        }else if (!strcmp(arg,"-di")){
            DeleteIptc = TRUE;
            DoModify |= MODIFY_JPEG;
        }else if (!strcmp(arg,"-dx")){
            DeleteXmp = TRUE;
            DoModify |= MODIFY_JPEG;
        }else if (!strcmp(arg, "-du")){
            DeleteUnknown = TRUE;
            DoModify |= MODIFY_JPEG;
        }else if (!strcmp(arg, "-purejpg")){
            DeleteExif = TRUE;
            DeleteComments = TRUE;
            DeleteIptc = TRUE;
            DeleteUnknown = TRUE;
            DeleteXmp = TRUE;
            DoModify |= MODIFY_JPEG;
        }else if (!strcmp(arg,"-ce")){
            EditComment = TRUE;
            DoModify |= MODIFY_JPEG;
        }else if (!strcmp(arg,"-cs")){
            CommentSavefileName = argv[++argn];
        }else if (!strcmp(arg,"-ci")){
            CommentInsertfileName = argv[++argn];
            DoModify |= MODIFY_JPEG;
        }else if (!strcmp(arg,"-cl")){
            CommentInsertLiteral = argv[++argn];
            DoModify |= MODIFY_JPEG;
        }else if (!strcmp(arg,"-mkexif")){
            CreateExifSection = TRUE;
            DoModify |= MODIFY_JPEG;

    // Output verbosity control
        }else if (!strcmp(arg,"-h")){
            Usage();
        }else if (!strcmp(arg,"-v")){
            ShowTags = TRUE;
        }else if (!strcmp(arg,"-q")){
            Quiet = TRUE;
        }else if (!strcmp(arg,"-V")){
            printf("Jhead version: "JHEAD_VERSION"   Compiled: "__DATE__"\n");
            exit(0);
        }else if (!strcmp(arg,"-exifmap")){
            DumpExifMap = TRUE;
        }else if (!strcmp(arg,"-se")){
            SupressNonFatalErrors = TRUE;
        }else if (!strcmp(arg,"-c")){
            ShowConcise = TRUE;
        }else if (!strcmp(arg,"-nofinfo")){
            ShowFileInfo = 0;

    // Thumbnail manipulation options
        }else if (!strcmp(arg,"-dt")){
            TrimExif = TRUE;
            DoModify |= MODIFY_JPEG;
        }else if (!strcmp(arg,"-st")){
            ThumbSaveName = argv[++argn];
            DoModify |= READ_JPEG;
        }else if (!strcmp(arg,"-rt")){
            ThumbInsertName = argv[++argn];
            DoModify |= MODIFY_JPEG;
        }else if (!memcmp(arg,"-rgt", 4)){
            RegenThumbnail = 160;
            sscanf(arg+4, "%d", &RegenThumbnail);
            if (RegenThumbnail > 320){
                ErrFatal("Specified thumbnail geometry too big!");
            }
            DoModify |= MODIFY_JPEG;

    // Rotation tag manipulation
        }else if (!strcmp(arg,"-autorot")){
            AutoRotate = 1;
            DoModify |= MODIFY_JPEG;
        }else if (!strcmp(arg,"-norot")){
            AutoRotate = 1;
            ZeroRotateTagOnly = 1;
            DoModify |= MODIFY_JPEG;

    // Date/Time manipulation options
        }else if (!memcmp(arg,"-n",2)){
            RenameToDate = 1;
            DoModify |= READ_JPEG; // Rename doesn't modify file, so count as read action.
            arg+=2;
            if (*arg == 'f'){
                // Accept -nf, but -n does the same thing now.
                arg++;
            }
            if (*arg){
                // A strftime format string is supplied.
                strftime_args = arg;
                #ifdef _WIN32
                    SlashToNative(strftime_args);
                #endif
                //printf("strftime_args = %s\n",arg);
            }
        }else if (!strcmp(arg,"-a")){
            #ifndef _WIN32
                ErrFatal("Error: -a only supported in Windows version");
            #else
                RenameAssociatedFiles = TRUE;
            #endif
        }else if (!strcmp(arg,"-ft")){
            Exif2FileTime = TRUE;
            DoModify |= MODIFY_ANY;
        }else if (!memcmp(arg,"-ta",3)){
            // Time adjust feature.
            int hours, minutes, seconds, n;
            minutes = seconds = 0;
            if (arg[3] != '-' && arg[3] != '+'){
                ErrFatal("Error: -ta must be followed by +/- and a time");
            }
            n = sscanf(arg+4, "%d:%d:%d", &hours, &minutes, &seconds);

            if (n < 1){
                ErrFatal("Error: -ta must be immediately followed by time");
            }
            if (ExifTimeAdjust) ErrFatal("Can only use one of -da or -ta options at once");
            ExifTimeAdjust = hours*3600 + minutes*60 + seconds;
            if (arg[3] == '-') ExifTimeAdjust = -ExifTimeAdjust;
            DoModify |= MODIFY_JPEG;
        }else if (!memcmp(arg,"-da",3)){
            // Date adjust feature (large time adjustments)
            time_t NewDate, OldDate = 0;
            char * pOldDate;
            NewDate = ParseCmdDate(arg+3);
            pOldDate = strstr(arg+1, "-");
            if (pOldDate){
                OldDate = ParseCmdDate(pOldDate+1);
            }else{
                ErrFatal("Must specifiy second date for -da option");
            }
            if (ExifTimeAdjust) ErrFatal("Can only use one of -da or -ta options at once");
            ExifTimeAdjust = NewDate-OldDate;
            DoModify |= MODIFY_JPEG;
        }else if (!memcmp(arg,"-dsft",5)){
            // Set file time to date/time in exif
            FileTimeToExif = TRUE;
            DoModify |= MODIFY_JPEG;
        }else if (!memcmp(arg,"-ds",3)){
            // Set date feature
            int a;
            // Check date validity and copy it.  Could be incompletely specified.
            strcpy(DateSet, "0000:01:01");
            for (a=0;arg[a+3];a++){
                if (isdigit(DateSet[a])){
                    if (!isdigit(arg[a+3])){
                        a = 0;
                        break;
                    }
                }else{
                    if (arg[a+3] != ':'){
                        a=0;
                        break;
                    }
                }
                DateSet[a] = arg[a+3];
            }
            if (a < 4 || a > 10){
                ErrFatal("Date must be in format YYYY, YYYY:MM, or YYYY:MM:DD");
            }
            DateSetChars = a;
            DoModify |= MODIFY_JPEG;
        }else if (!memcmp(arg,"-ts",3)){
            // Set the exif time.
            // Time must be specified as "yyyy:mm:dd-hh:mm:ss"
            char * c;
            struct tm tm;

            c = strstr(arg+1, "-");
            if (c) *c = ' '; // Replace '-' with a space.
            
            if (!Exif2tm(&tm, arg+3)){
                ErrFatal("-ts option must be followed by time in format yyyy:mm:dd-hh:mm:ss\n"
                        "Example: jhead -ts2001:01:01-12:00:00 foo.jpg");
            }

            ExifTimeSet  = mktime(&tm);

            if ((int)ExifTimeSet == -1) ErrFatal("Time specified is out of range");
            DoModify |= MODIFY_JPEG;

    // File matching and selection
        }else if (!strcmp(arg,"-model")){
            if (argn+1 >= argc) Usage(); // No extra argument.
            FilterModel = argv[++argn];
        }else if (!strcmp(arg,"-exonly")){
            ExifOnly = 1;
        }else if (!strcmp(arg,"-orp")){
            PortraitOnly = 1;
        }else if (!strcmp(arg,"-orl")){
            PortraitOnly = -1;
        }else if (!strcmp(arg,"-cmd")){
            if (argn+1 >= argc) Usage(); // No extra argument.
            ApplyCommand = argv[++argn];
            DoModify |= MODIFY_ANY;

#ifdef MATTHIAS
        }else if (!strcmp(arg,"-ca")){
            // Its a literal comment.  Add.
            AddComment = argv[++argn];
            DoModify |= MODIFY_JPEG;
        }else if (!strcmp(arg,"-cr")){
            // Its a literal comment.  Remove this keyword.
            RemComment = argv[++argn];
            DoModify |= MODIFY_JPEG;
        }else if (!strcmp(arg,"-ar")){
            AutoResize = TRUE;
            ShowConcise = TRUE;
            ApplyCommand = (char *)1; // Must be non null so it does commands.
            DoModify |= MODIFY_JPEG;
#endif // MATTHIAS
        }else{
            printf("Argument '%s' not understood\n",arg);
            printf("Use jhead -h for list of arguments\n");
            exit(-1);
        }
        if (argn >= argc){
            // Used an extra argument - becuase the last argument 
            // used up an extr argument.
            ErrFatal("Extra argument required");
        }
    }
    if (argn == argc){
        ErrFatal("No files to process.  Use -h for help");
    }

    if (ThumbSaveName != NULL && strcmp(ThumbSaveName, "&i") == 0){
        printf("Error: By specifying \"&i\" for the thumbail name, your original file\n"
               "       will be overwitten.  If this is what you really want,\n"
               "       specify  -st \"./&i\"  to override this check\n");
        exit(0);
    }

    if (RegenThumbnail){
        if (ThumbSaveName || ThumbInsertName){
            printf("Error: Cannot regen and save or insert thumbnail in same run\n");
            exit(0);
        }
    }

    if (EditComment){
        if (CommentSavefileName != NULL || CommentInsertfileName != NULL){
            printf("Error: Cannot use -ce option in combination with -cs or -ci\n");
            exit(0);
        }
    }


    if (ExifXferScrFile){
        if (FilterModel || ApplyCommand){
            ErrFatal("Error: Filter by model and/or applying command to files\n"
            "   invalid while transferring Exif headers");
        }
    }

    FileSequence = 0;
    for (;argn<argc;argn++){
        FilesMatched = FALSE;

        #ifdef _WIN32
            SlashToNative(argv[argn]);
            // Use my globbing module to do fancier wildcard expansion with recursive
            // subdirectories under Windows.
            MyGlob(argv[argn], ProcessFile);
        #else
            // Under linux, don't do any extra fancy globbing - shell globbing is 
            // pretty fancy as it is - although not as good as myglob.c
            ProcessFile(argv[argn]);
        #endif

        if (!FilesMatched){
            fprintf(stderr, "Error: No files matched '%s'\n",argv[argn]);
        }
    }
    
    if (FileSequence == 0){
        return EXIT_FAILURE;
    }else{
        return EXIT_SUCCESS;
    }
}
*/

