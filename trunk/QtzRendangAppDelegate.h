//  QtzRendangAppDelegate.h
//  QtzRendang

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <QTKit/QTKit.h>
#import <QuickTime/QuickTime.h>

// This little class delegates all the QCView drag messages to the path control to 
// support drag&drop of .qtz file on to the QCView.
@interface PathControlPeerQCView : QCView {

IBOutlet NSPathControl* dralagate;
}

@end


@interface QtzRendangAppDelegate : NSObject <NSApplicationDelegate> {
NSWindow *window;

IBOutlet NSPathControl* sourcePath;
IBOutlet NSPathControl* audioSourcePath;

IBOutlet PathControlPeerQCView* qtzPreview;

IBOutlet NSPopUpButton* aspectRatio;
IBOutlet NSMenuItem* aspectRatio16x9;
IBOutlet NSMenuItem* aspectRatio4x3;
IBOutlet NSMenuItem* aspectRatioCustom;
IBOutlet NSTextField* width;
IBOutlet NSTextField* height;
IBOutlet NSTextField* duration;
IBOutlet NSTextField* fps;
IBOutlet NSTextField* blankIntroDuration;

IBOutlet QCCompositionParameterView* qtzParams;

IBOutlet NSPathControl* destinationPath;
IBOutlet NSTextField* destinationFilename;

IBOutlet NSButton* renderIt;

IBOutlet NSProgressIndicator* progress;

bool userHasSpecifiedName;

bool renderingNow;
}

@property (assign) IBOutlet NSWindow *window;

-(IBAction)sourcePathChanged:(id)sender;
-(IBAction)audioSrcPathChanged:(id)sender;

-(IBAction)widthChanged:(id)sender;
-(IBAction)heightChanged:(id)sender;
-(IBAction)aspectRatioChanged:(id)sender;

-(IBAction)renderClicked:(id)sender;

-(void)setUIEnabled:(BOOL)ebl;
-(void)setUIEnabled;

-(NSURL*)destinationURL;
-(NSString*)destinationFile;
-(double)fps;

-(void)setCompResolution:(NSSize)res;
-(void)renderMovie:(NSString*)composition frameSize:(NSSize)res duration:(double)duration frameDuration:(double)frameDuration introDuration:(double)introDuration;

-(void)updateProgress:(double)curTime duration:(double)duration;
-(void)updateProgress:(NSNumber*)curTime;

@end
