//  QtzRendangAppDelegate.m
//  QtzRendang

#import "QtzRendangAppDelegate.h"
#import "QTMovieExtensions.h"

@implementation PathControlPeerQCView

-(void)awakeFromNib
{
   [super awakeFromNib];
   [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
}

-(void)setDralagate:(NSPathControl*)dral
{
   dralagate = dral;
}

-(NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender
{
   return [dralagate draggingEntered:sender];
}

-(NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender
{
   return [dralagate draggingUpdated:sender];
}

-(void)draggingExited:(id < NSDraggingInfo >)sender
{
   [dralagate draggingExited:sender];
}

-(BOOL)prepareForDragOperation:(id <NSDraggingInfo >)sender
{
   return [dralagate prepareForDragOperation:sender];
}

-(BOOL)performDragOperation:(id < NSDraggingInfo >)sender
{
   return [dralagate performDragOperation:sender];
}

-(void)concludeDragOperation:(id < NSDraggingInfo >)sender
{
   [dralagate concludeDragOperation:sender];
}

@end

@implementation QtzRendangAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	// Insert code here to initialize your application 
   [destinationPath setURL:[NSURL fileURLWithPath:[@"~/Movies" stringByExpandingTildeInPath] isDirectory:YES]];
   
   // init quicktime - we will be using it on a worker thread, it needs to be inited on the main thread
   [[[QTMovie alloc] init] autorelease];
   
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:@"NSControlTextDidChangeNotification" object:destinationFilename];
}

-(void)dealloc
{
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   [super dealloc];
}

-(IBAction)sourcePathChanged:(id)sender
{
   NSURL* path = [sourcePath URL];
   if ([qtzPreview loadCompositionFromFile:[path path]])
   {
      [qtzPreview startRendering];
      
      // and use the filename as the default if there is nothing there
      //if ([[destinationFilename stringValue] length] == 0)
      if (!userHasSpecifiedName)
      {
         [destinationFilename setStringValue:[[[path URLByDeletingPathExtension] lastPathComponent] stringByAppendingString:@".mov"]];
         userHasSpecifiedName = NO; // reaffirm this, the textChanged gets called by the setStringValue
      }
   }
}

-(IBAction)widthChanged:(id)sender
{
   // TODO don't do anything if the text hasn't changed (manual resize when focus on textedit bug)

   const double ratio16x9 = 9.0 / 16.0;
   const double ratio4x3 = 3.0 / 4.0;

   int newWidth = [width intValue];
   int newHeight = [height intValue];
   if ([aspectRatio selectedItem] == aspectRatio16x9)
      newHeight = newWidth * ratio16x9;
   if ([aspectRatio selectedItem] == aspectRatio4x3)
      newHeight = newWidth * ratio4x3;
   
   [self setCompResolution:NSMakeSize(newWidth, newHeight)];
}

-(IBAction)heightChanged:(id)sender
{
   // TODO don't do anything if the text hasn't changed (manual resize when focus on textedit bug)

   const double ratio16x9 = 16.0 / 9.0;
   const double ratio4x3 = 4.0 / 3.0;

   int newWidth = [width intValue];
   int newHeight = [height intValue];
   if ([aspectRatio selectedItem] == aspectRatio16x9)
      newWidth = newHeight * ratio16x9;
   if ([aspectRatio selectedItem] == aspectRatio4x3)
      newWidth = newHeight * ratio4x3;
   
   [self setCompResolution:NSMakeSize(newWidth, newHeight)];
}

-(IBAction)aspectRatioChanged:(id)sender
{
   // pretend the height changed, so a new width based on current aspect ratio
   [self heightChanged:sender];
}

-(IBAction)renderClicked:(id)sender
{
   if (!renderingNow)
      [self renderMovie:[[sourcePath URL] path] frameSize:NSMakeSize([width intValue], [height intValue]) duration:[duration doubleValue] frameDuration:(1.0/[self fps])];
}

-(void) textDidChange:(NSNotification*)note 
{
   if ([note object] == destinationFilename)
      userHasSpecifiedName = YES;
}

-(double)fps
{
   double frames = [fps doubleValue];
   if (frames < 0 || frames > 999)
      frames = 30.0;
   return frames;
}

-(NSString*)destinationFile
{
   NSString* dest = [destinationFilename stringValue];
   if ([dest length] == 0)
      dest = [[sourcePath URL] resourceSpecifier];
   if ([dest length] == 0)
      dest = @"tmp.mov";
   
   return dest;
}

-(NSURL*)destinationURL
{
   NSURL* dest = [destinationPath URL];

   NSFileManager* fileMan = [[[NSFileManager alloc] init] autorelease];

   BOOL isDirectory;
   BOOL exists = [fileMan fileExistsAtPath:[dest path] isDirectory:&isDirectory];
   if (exists && isDirectory)
      dest = [dest URLByAppendingPathComponent:[self destinationFile]];
   
   // ensure extension is .mov
   if ([[dest pathExtension] caseInsensitiveCompare:@"mov"] != NSOrderedSame)
      dest = [[dest URLByDeletingPathExtension] URLByAppendingPathExtension:@"mov"];
      
   return dest;
}

-(void)setCompResolution:(NSSize)res
{
   // crazy lower limit
   if (res.width < 2)
      res.width = 2;
   if (res.height < 2)
      res.height = 2;

   [width setFloatValue:res.width];
   [height setFloatValue:res.height];
   
   double newAspectRatio = res.width / res.height;
   
   NSSize currentPreviewSz = [qtzPreview frame].size;
   
// height-constant approach
//   int newwidth = floor(currentPreviewSz.height * newAspectRatio);
//   if (newwidth != currentPreviewSz.width)
//   {
//      // reshape the preview by widening/narrowing it
//      NSRect frame = [[self window] frame];
//      frame.size.width += newwidth - currentPreviewSz.width;
//      [[self window] setFrame:frame display:YES animate:YES];
//   }

// width-constant approach
   int newheight = floor(currentPreviewSz.width * (1.0 / newAspectRatio));
   if (newheight != currentPreviewSz.height)
   {
      // reshape the preview by widening/narrowing it
      NSRect frame = [[self window] frame];
      frame.size.height += newheight - currentPreviewSz.height;
      [[self window] setFrame:frame display:YES animate:YES];
   }
}

-(void)setUIEnabled
{
   [self setUIEnabled:YES];
}

-(void)setUIEnabled:(BOOL)ebl
{
   renderingNow = !ebl;
   
   if (ebl)
   {
      [progress stopAnimation:self];
      [qtzPreview resumeRendering];
   }
   else
   {
      [progress startAnimation:self];
      [qtzPreview pauseRendering];
   }

   [sourcePath setEnabled:ebl];

   [aspectRatio setEnabled:ebl];
   [width setEnabled:ebl];
   [height setEnabled:ebl];
   [duration setEnabled:ebl];
   [fps setEnabled:ebl];

   [qtzParams setHidden:!ebl]; // slightly suck

   [destinationPath setEnabled:ebl];
   [destinationFilename setEnabled:ebl];
   
   [renderIt setEnabled:ebl];
}

-(void)renderMovie:(NSString*)compositionFile frameSize:(NSSize)res duration:(double)durationg frameDuration:(double)frameDuration
{      
   // confirm overwrite if exists
   NSURL* saveToUrl = [self destinationURL];
   NSFileManager* fileMan = [[[NSFileManager alloc] init] autorelease];
   BOOL isDirectory = NO;
   BOOL exists = [fileMan fileExistsAtPath:[saveToUrl path] isDirectory:&isDirectory];

// TODOs with these error alerts:
// - should be sheets
// - overwrite buttons should be cancel (default) overwrite (currently in backwards order)
// this is all due to me using the lazy alertWithMessageText init method

   if (isDirectory)
   {
      NSAlert* al = [NSAlert alertWithMessageText:@"Please specify a destination filename." defaultButton:@"OK" alternateButton:nil otherButton:nil 
         informativeTextWithFormat:@"The destination filename \"%@\" is a folder.", [saveToUrl path], nil];
      [al runModal];
      return;
   }

   if (exists)
   {
      NSAlert* al = [NSAlert alertWithMessageText:@"Do you want to overwrite an existing movie file?" defaultButton:@"Cancel" alternateButton:@"Overwrite" otherButton:nil 
         informativeTextWithFormat:@"The destination filename \"%@\" already exists and will be overwritten.", [saveToUrl path], nil];
      if ([al runModal] != NSAlertAlternateReturn)
         return;
   }

   renderingNow = YES;
   [progress startAnimation:self]; // ha, this would work if we had things on another thread... which we should do asap!
   [self setUIEnabled:NO];
   
   NSBlockOperation* theOp = [NSBlockOperation blockOperationWithBlock: 
   ^{
      QTMovie *mMovie = nil;
   
      // Create a QTMovie with a writable data reference
      // using the destination file, so that user can put it on a disk with heaps of space ..
      mMovie = [[QTMovie alloc] initToWritableFile:[saveToUrl path] error:NULL];

      if (mMovie)
      {
         // mark the movie as editable
         [mMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];

         // keep it around until we are done with it...
         [mMovie retain];

         int pixW = res.width;
         int pixH = res.height;
         double timeStep = frameDuration;
         double timeEnd = durationg;

         NSAutoreleasePool*			pool = [NSAutoreleasePool new];
         NSTimeInterval				time;
         NSImage* frame;

         // create a QTTime value to be used as a duration when adding 
         // the image to the movie
         QTTime durationqt     = QTMakeTimeWithTimeInterval(timeStep);
         // when adding images we must provide a dictionary
         // specifying the codec attributes
         NSDictionary *myDict = nil;
         myDict = [NSDictionary dictionaryWithObjectsAndKeys:@"mp4v",
                                                  QTAddImageCodecType,
                                                  [NSNumber numberWithLong:codecNormalQuality],
                                                  QTAddImageCodecQuality,
                                                  nil];
                                                              
         QCComposition* composition = [QCComposition compositionWithFile:compositionFile];
         CGColorSpaceRef co = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
         QCRenderer* renderer = [[QCRenderer alloc]initOffScreenWithSize:NSMakeSize(pixW, pixH) colorSpace:co composition:composition];
         for (time=0; time <= timeEnd; time += timeStep)
         {
            NSAutoreleasePool*			pool2 = [NSAutoreleasePool new];
            [renderer renderAtTime:time arguments:nil];
            frame = [renderer snapshotImage];
            [mMovie addImage:frame forDuration:durationqt withAttributes:myDict];
            [pool2 release];
         }
         CFRelease(co);

         [pool release];

         // now save the file
         [mMovie updateMovieFile];
         [mMovie release];
         mMovie = nil;
      }
   }];

   [theOp setCompletionBlock:
   ^{
      [self performSelectorOnMainThread:@selector(setUIEnabled) withObject:nil waitUntilDone:YES];
   }];
   
   NSOperationQueue* aQueue = [[NSOperationQueue alloc] init];
   [aQueue addOperation:theOp];
   
   return;
}



@end
