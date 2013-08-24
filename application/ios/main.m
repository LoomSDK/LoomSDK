#import <Foundation/NSAutoreleasePool.h>
#import <UIKit/UIKit.h>

void loom_appSetup();
void loom_appShutdown();

int main(int argc, char *argv[]) 
{
   NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

   loom_appSetup();

    // Redirect stderr to a console.log file.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:@"console.log"];
    freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"w",stderr);

   UIApplicationMain(argc, argv, nil, @"AppController");

   loom_appShutdown();

   [pool release];

   return 0;
}