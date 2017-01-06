//
//  KIdCanvasPage.m
//  JijiScribble
//
//  Created by Kavya Valavala on 7/21/14.
//  Copyright (c) 2014 Vaayoo. All rights reserved.
//

#import "KIdCanvasPage.h"
#import "HRColorPickerView.h"
#import "HRBrightnessSlider.h"
#import "HRColorMapView.h"
#import "VSCore.h"
//#import "VDBFunctions.h"
//#import "WebService.h"
//#import "ResponseParser.h"
//#import "AsyncUploader.h"
#import "btSimplePopUP.h"
#import "JGActionSheet.h"
#import "ProgressHUD.h"

//CONSTANTS:

#define kPaletteHeight			30
#define kPaletteSize			5
#define kMinEraseInterval		0.5

// Padding for margins
#define kLeftMargin				10.0
#define kTopMargin				10.0
#define kRightMargin			10.0


@interface KIdCanvasPage ()<UIGestureRecognizerDelegate , UIImagePickerControllerDelegate ,JGActionSheetDelegate,UIAlertViewDelegate,UIScrollViewDelegate>

{
    HRColorPickerView *colorPickerView;
    UIColor *_color;
    UITapGestureRecognizer *_tapgesture;
    UIScrollView           *_scrollView;
    UIImageView            *backGroundBlurr ;
    NSString               *file;
    btSimplePopUP *popUp;
    BOOL          isArtWorkSaved;
    BOOL          drawEventOccurred;
    BOOL          isImageSaved;
    JGActionSheet *_simple;
    JGActionSheet *_currentAnchoredActionSheet;
    int drawCount;
    int undoCount;
    CGSize result;
}

@end

@implementation KIdCanvasPage

@synthesize drawingView, kidInfoDict , iseditMode, savedImagePath , shareArtButton , bgImageView,scrollImageView;

#pragma mark - JGActionSheetDelegate

- (void)actionSheetWillPresent:(JGActionSheet *)actionSheet {
    NSLog(@"Action sheet %p will present", actionSheet);
}

- (void)actionSheetDidPresent:(JGActionSheet *)actionSheet {
    NSLog(@"Action sheet %p did present", actionSheet);
}

- (void)actionSheetWillDismiss:(JGActionSheet *)actionSheet {
    NSLog(@"Action sheet %p will dismiss", actionSheet);
    _currentAnchoredActionSheet = nil;
}

- (void)actionSheetDidDismiss:(JGActionSheet *)actionSheet
{
    NSLog(@"Action sheet %p did dismiss", actionSheet);
}



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        colorPickerView = [[HRColorPickerView alloc] init];
        colorPickerView.color=[UIColor blueColor];
        file=@"";
        isArtWorkSaved=NO;
        iseditMode=NO;
        drawEventOccurred=NO;
        isImageSaved=NO;
        drawCount=0;
        undoCount=0;
        [_undoButton setEnabled:NO];
        [_redoButton setEnabled:NO];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        // Custom initialization
        colorPickerView = [[HRColorPickerView alloc] init];
        colorPickerView.color=[UIColor blueColor];
        file=@"";
        isArtWorkSaved=NO;
        iseditMode=NO;
        drawEventOccurred=NO;
        isImageSaved=NO;
        drawCount=0;
        undoCount=0;
        [_undoButton setEnabled:NO];
        [_redoButton setEnabled:NO];
    }
    return self;

}
- (void)viewDidLoad
{
     result=[UIScreen mainScreen].bounds.size;
    [super viewDidLoad];
    
    [self deleteFilesfromUndoRedoFloder];
    
    CGColorRef coloref = [colorPickerView.color CGColor];
    
    const CGFloat* components = CGColorGetComponents(coloref);
    
    CGFloat red = components[0];
    CGFloat green = components[1];
    CGFloat blue = components[2];
	// Defer to the OpenGL view to set the brush color
   [drawingView setBrushColorWithRed:red green:green blue:blue];
    [drawingView setViewDelegate:self];
    [ drawingView.layer setBorderColor: [[UIColor lightGrayColor] CGColor]];
    [drawingView.layer setBorderWidth: 2.0];
    [drawingView.layer setCornerRadius:10];
    [drawingView.layer setMasksToBounds:YES];
    scrollImageView.delegate =self;
//    [drawingView addSubview:bgImageView];
   
    
//    if (iseditMode)
    if (savedImagePath)
    {
        drawingView.isEditMode=YES;
        drawingView.savedArtWorkimagePath=savedImagePath;
//        [bgImageView setImage:[UIImage imageWithContentsOfFile:savedImagePath]];
//        bgImageView.image = [UIImage imageWithContentsOfFile:savedImagePath];
        file=savedImagePath;
    }
    
    bgImageView.frame = scrollImageView.bounds;
    [bgImageView setContentMode:UIViewContentModeScaleAspectFit];
    scrollImageView.contentSize = CGSizeMake(bgImageView.frame.size.width, bgImageView.frame.size.height);
    scrollImageView.maximumZoomScale = 4.0;
    scrollImageView.minimumZoomScale = 1.0;
    scrollImageView.delegate = self;
   	// Look in the Info.plist file and you'll see the status bar is hidden
	// Set the style to black so it matches the background of the application
	
	// Load the sounds
	/*NSBundle *mainBundle = [NSBundle mainBundle];
	erasingSound = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Erase" ofType:@"caf"]];
	selectSound =  [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Select" ofType:@"caf"]];
    */
    
	// Erase the view when recieving a notification named "shake" from the NSNotificationCenter object
	// The "shake" nofification is posted by the PaintingWindow object when user shakes the device
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eraseView) name:@"shake" object:nil];

    //
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // iOS 7
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    } else {
        // iOS 6
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    }

    //Custom PopUp  View
    
//    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
//    {
//        popUp = [[btSimplePopUP alloc]initWithItemImage:@[
//                                                          [UIImage imageNamed:@"color.png"],
//                                                          [UIImage imageNamed:@"brush.png"],
//                                                          [UIImage imageNamed:@"insert picture.png"],
//                                                          [UIImage imageNamed:@"sticker.png"],
//                                                          [UIImage imageNamed:@"save.png"],
//                                                          [UIImage imageNamed:@"page layout.png"],
//                                                          //                                                      [UIImage imageNamed:@"page layout.png"]
//                                                          
//                                                          ]
//                                              andTitles:    @[
//                                                              
//                                                              ]
//                 
//                                         andActionArray:@[
//                                                          ^{
//            
//            __block UIViewController *temp = [[UIViewController alloc]init];
//            temp.view.backgroundColor = [UIColor blueColor];
//            [self.navigationController presentViewController:temp
//                                                    animated:YES
//                                                  completion:^{
//                                                      
//                                                      [temp dismissViewControllerAnimated:YES completion:nil];
//                                                  }];
//            [self launch_colorPicker];
//            
//        },
//                                                           ^{
//            [self chooseBrushes_clicked];
//        },
//                                                           ^{
//            [self browsePics];
//        },
//                                                           ^{
//            [self insertStickers];
//        },
//                                                           ^{
//            [self saveImage];
//        },
//                                                           ^{
//            [self launchPageLayouts];
//        },
//                                                           ^{
//            //  [self insertStickers];
//        }]
//                                    addToViewController:self];
//        
//
//    }
//    
//    else
//    {
//        popUp = [[btSimplePopUP alloc]initWithItemImage:@[
//                                                          [UIImage imageNamed:@"color.png"],
//                                                          [UIImage imageNamed:@"brush.png"],
//                                                          [UIImage imageNamed:@"insert picture.png"],
//                                                          [UIImage imageNamed:@"save.png"],
//                                                          [UIImage imageNamed:@"erase.png"],
//                                                          [UIImage imageNamed:@"page layout.png"],
//                                                          //                                                      [UIImage imageNamed:@"page layout.png"]
//                                                          
//                                                          ]
//                                              andTitles:    @[
//                                                              
//                                                              ]
//                 
//                                         andActionArray:@[
//                                                          ^{
//            
//            __block UIViewController *temp = [[UIViewController alloc]init];
//            temp.view.backgroundColor = [UIColor blueColor];
//            [self.navigationController presentViewController:temp
//                                                    animated:YES
//                                                  completion:^{
//                                                      
//                                                      [temp dismissViewControllerAnimated:YES completion:nil];
//                                                  }];
//            [self launch_colorPicker];
//            
//        },
//                                                           ^{
//            [self chooseBrushes_clicked];
//        },
//                                                           ^{
//            [self browsePics];
//        },
//                                                           
//                                                           ^{
//            [self saveImage];
//        },
//                                                           ^{
//            [self launchEraser];
//        },
//                                                           ^{
//            [self launchPageLayouts];
//        },
//                                                           ^{
//            //  [self insertStickers];
//        }]
//                                    addToViewController:self];
//        
//
//    }
////      [self.view addSubview:popUp];
//    [popUp setPopUpStyle:BTPopUpStyleDefault];
//    [popUp setPopUpBorderStyle:BTPopUpBorderStyleDefaultNone];
//    
    
    
    
    //programetically add view
    
    
    
    
//    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
//    {
//        // The device is an iPad running iOS 3.2 or later.
//        _scrollView=[[UIScrollView alloc] initWithFrame:CGRectMake(0,835,768,91)];
//        
//    }
//    else
//    {
        // The device is an iPhone or iPod touch.
        _scrollView=[[UIScrollView alloc] initWithFrame:CGRectMake(5, result.height-50, result.width-10, 50)];
        
//    }

    _scrollView.scrollEnabled=YES;
//    _scrollView.pagingEnabled=YES;
    
    //adding BackGround image to UISCrollView
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:_scrollView.frame];
    imageView.image =[UIImage imageNamed:@"Plain.png"] ;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:imageView];
//    imageView.tag=35;
    [_scrollView setBackgroundColor:[UIColor clearColor]];
    
    [self.view addSubview:_scrollView];
    
    [VSCore copyPlistFileFromMainBundle:@"ScribblingIcons" ToDocumentPath:@"ScribblingIcons_M"];
    
    NSMutableString *plistPath = [[VSCore getPlistPath:@"ScribblingIcons_M"] mutableCopy];
    
    
    NSArray *arrayData=[[NSArray alloc] initWithContentsOfFile:plistPath];
    
    for (int i=1; i <= [arrayData count]; i++)
    {
        
        NSDictionary *dict=[arrayData objectAtIndex:i-1];
        
        UIImageView *imgView =[[UIImageView alloc] init];
        //  self.imgView = [[UIImageView alloc] init];
        _tapgesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedgestureForScribbling:)];
        [imgView addGestureRecognizer:_tapgesture];
        [imgView setMultipleTouchEnabled:YES];
        [imgView setUserInteractionEnabled:YES];
//        [ imgView.layer setBorderColor: [[UIColor lightGrayColor] CGColor]];
//        [imgView.layer setBorderWidth: 2.0];
        
        [imgView setImage:[UIImage imageNamed:[dict objectForKey:@"Name"]]];
        
        CGRect rectt = imgView.frame;
        rectt.size.height = 32;
        rectt.size.width = 33;
        imgView.frame = rectt;
        imgView.tag=i;
        //        self.imgView.layer.cornerRadius = self.imgView.frame.size.height/2;
        //        self.imgView.layer.masksToBounds= YES;
        CALayer *imglayer=[imgView layer];
//        [imglayer setCornerRadius:10];
        imglayer.masksToBounds=YES;
        
        [_scrollView addSubview:imgView];
        _scrollView.pagingEnabled=YES;
        
        [_scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
        
    }
    
    [self layoutScrollImagesForScribbling];
    
}


- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView {
    NSLog(@"viewForZoomingInScrollView");
    return self.drawingView;
}

/*Launch eraser for Ipad */
-(IBAction)btn_eraserClick:(id)sender
{
    [self launchEraser];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void)deleteFilesfromUndoRedoFloder
{
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    NSError *error = nil;
    NSArray *directoryContents = [fileMgr contentsOfDirectoryAtPath:[VSCore getUndoRedoFolder] error:&error];
    if (error == nil) {
        for (NSString *path in directoryContents) {
            NSString *fullPath = [[VSCore getUndoRedoFolder] stringByAppendingPathComponent:path];
            BOOL removeSuccess = [fileMgr removeItemAtPath:fullPath error:&error];
            if (!removeSuccess) {
                // Error handling
            }
        }
    } else {
        // Error handling
    }
}

-(IBAction)undoBtn_Clicked:(id)sender
{
    if (undoCount == 0)
    {
        undoCount=drawCount;
        if(undoCount == 1)
        {
            [_undoButton setEnabled:NO];
            [_redoButton setEnabled:NO];
            
            NSLog(@"Last round for Undo operation");
            drawEventOccurred=NO;
            //undoCount --;
            NSString *undoRedoPath = [[VSCore getUndoRedoFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.jpg",undoCount]];
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:undoRedoPath];
            if (fileExists)
            {
                NSLog(@"FileExists");
                drawingView.isEditMode=YES;
                drawingView.savedArtWorkimagePath=undoRedoPath;
                [drawingView layoutSubviews];
                drawingView.isEditMode=NO;
                [drawingView erase];
                
            }
            
            [self deleteFilesfromUndoRedoFloder];
            drawCount=0;
        }else{

        undoCount--;
        NSString *undoRedoPath = [[VSCore getUndoRedoFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.jpg",undoCount]];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:undoRedoPath];
        if (fileExists)
        {
            NSLog(@"FileExists");
            drawingView.isEditMode=YES;
            drawingView.savedArtWorkimagePath=undoRedoPath;
            [drawingView layoutSubviews];
            drawingView.isEditMode=NO;
        }
        }
    }
    else if(undoCount == 1)
    {
        [_undoButton setEnabled:NO];
        [_redoButton setEnabled:NO];
        
        NSLog(@"Last round for Undo operation");
        drawEventOccurred=NO;
        //undoCount --;
        NSString *undoRedoPath = [[VSCore getUndoRedoFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.jpg",undoCount]];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:undoRedoPath];
        if (fileExists)
        {
            NSLog(@"FileExists");
            drawingView.isEditMode=YES;
            drawingView.savedArtWorkimagePath=undoRedoPath;
            [drawingView layoutSubviews];
            drawingView.isEditMode=NO;
            [drawingView erase];

        }

        [self deleteFilesfromUndoRedoFloder];
        drawCount=0;
    }
    
    else
    {
        undoCount --;
        NSString *undoRedoPath = [[VSCore getUndoRedoFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.jpg",undoCount]];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:undoRedoPath];
        if (fileExists)
        {
            NSLog(@"FileExists");
            drawingView.isEditMode=YES;
            drawingView.savedArtWorkimagePath=undoRedoPath;
            [drawingView layoutSubviews];
            drawingView.isEditMode=NO;
        }

    }
}
-(IBAction)redoBtn_clciked:(id)sender
{
    if (undoCount == drawCount)
    {
        NSLog(@"No artwork to perform REDO");
    }
    else
    {
        undoCount++;
        NSString *undoRedoPath = [[VSCore getUndoRedoFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.jpg",undoCount]];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:undoRedoPath];
        if (fileExists)
        {
            NSLog(@"FileExists");
            drawingView.isEditMode=YES;
            drawingView.savedArtWorkimagePath=undoRedoPath;
            [drawingView layoutSubviews];
            drawingView.isEditMode=NO;
        }

    }
    
}
// Called when receiving the "shake" notification; plays the erase sound and redraws the view
-(void) eraseView
{
    file=@"";
   // [shareArtButton setEnabled:NO];

	if(CFAbsoluteTimeGetCurrent() > lastTime + kMinEraseInterval) {
        //prasuna add this
        [bgImageView setImage:[UIImage imageNamed:@"Plain.png"]];
		[erasingSound play];
		[drawingView erase];
		lastTime = CFAbsoluteTimeGetCurrent();
	}
}


- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    // Was there an error?
    if (error != nil)
    {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message" message:@"ArtWork has not been saved." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        
//        [alert show];
        
    }
    else  // No errors
    {
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Image Has Been saved to your photo album" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        
       // [alert show];
    }
}

//-(IBAction)shareArt_clicked
//{
//    [self saveImageAndSendtoServer];
//    
//    if (iseditMode)
//    {
//        isImageSaved=YES;
//    }
//    if (isImageSaved)
//    {
//        ShareArtVC *_vc=[[ShareArtVC alloc] initWithNibName:@"ShareArtVC" bundle:nil];
//        
//        _vc.filePath=file;
//        _vc.kidInfoDict=kidInfoDict;
//        [self presentViewController:_vc animated:YES completion:NULL];
//        
//    }
//    
//}

-(void)saveImageforeveryDrawEventOccured
{
    
    //    CGSize newSize = CGSizeMake(320, 427);
    CGSize newSize = CGSizeMake(480, 480);
    UIGraphicsBeginImageContext( newSize );// a CGSize that has the size you want
    [[self imageRepresenation] drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    //image is the original UIImage
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    ////remove above this line once the 8192 problem is fixed
    
    //store the image as a jpeg file
    NSData *imD = [NSData dataWithData:UIImageJPEGRepresentation(newImage, 1.0f)];
    
    NSMutableString *filePath = [[NSMutableString alloc] initWithFormat:@"%@", [VSCore getUndoRedoFolder]];
    NSMutableString *filename = [NSMutableString stringWithFormat:@"%d.jpg",drawCount];
    file = [filePath stringByAppendingPathComponent:filename];
    
    if (![imD writeToFile:file atomically:YES])
    {
        NSLog (@"There was a problem writing the image %@", file);
    }
   else
   {
       NSLog(@"Image Saved Successfully");
   }

}
-(void)saveImage
{
    [self saveImageAndSendtoServer];
}


-(void)saveImageAndSendtoServer
{
    scribblingDone=YES;
    
    if (([file length] > 0) && drawEventOccurred)
    {
        isImageSaved=YES;
        drawEventOccurred=NO;
        
        UIImageWriteToSavedPhotosAlbum([self imageRepresenation], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        
        //    CGSize newSize = CGSizeMake(320, 427);
        CGSize newSize = CGSizeMake(480, 480);
        UIGraphicsBeginImageContext( newSize );// a CGSize that has the size you want
        [[self imageRepresenation] drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
        //image is the original UIImage
        UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        ////remove above this line once the 8192 problem is fixed
        
        //store the image as a jpeg file
        NSData *imD = [NSData dataWithData:UIImageJPEGRepresentation(newImage, 1.0f)];
        
        if (!iseditMode)
        {
            NSMutableString *filePath = [[NSMutableString alloc] initWithFormat:@"%@", [VSCore getImagesFolder]];
            NSMutableString *filename = [NSMutableString stringWithFormat:@"%@.jpg",[VSCore getUniqueFileName]];
            file = [filePath stringByAppendingPathComponent:filename];
            
            if (![imD writeToFile:file atomically:YES])
            {
                NSLog (@"There was a problem writing the image %@", file);
            }
            else
            {
                NSLog(@"Image Saved Succesfully");
                
             /*    NSMutableString *plistPath = [[VSCore getPlistPath:@"KidsProfiles_M"] mutableCopy];
                NSMutableArray *profilesArray=[NSMutableArray arrayWithContentsOfFile:plistPath];
                
                NSMutableDictionary *tempDict=[profilesArray objectAtIndex:[[kidInfoDict objectForKey:@"ObjectIndex"] intValue]];
                
                if ([tempDict objectForKey:@"myart"] != nil)
                {
                    [tempDict setObject:[[tempDict objectForKey:@"myart"] stringByAppendingFormat:@";%@",file] forKey:@"myart"];
                }
                else
                {
                    [tempDict setObject:file forKey:@"myart"];
                    
                }
                
                [profilesArray writeToFile:plistPath atomically:YES];
                
             */
            }
            
        }
        
        else
        {
            file=savedImagePath;
            [self removeImage:file];
//            [self updateArrayAndPlist];
            
            if (![imD writeToFile:file atomically:YES])
            {
                NSLog (@"There was a problem writing the image %@", file);
            }
            

        }
        
        
        /*-----Calculate Total chunk of the image and save Into Database ----*/
        
//        NSData *fileData = [NSData dataWithContentsOfFile:file];
//        
//        NSUInteger length = [fileData length];
//        //  NSUInteger chunkSize = 1024 * 1024 *2; // chunk size is 2MB
//        NSUInteger chunkSize = 1024 * 1024 *1;
//        NSInteger totalchunk=  length/chunkSize;
//        //   NSInteger currentchunk = 1;
//        
//        if(length % chunkSize != 0)
//        {
//            totalchunk = totalchunk+1;
//        }
//        
//        NSLog(@"total chunk is %ld", (long)totalchunk);
//        
//        VDBFunctions *_vdbfunctions=[[VDBFunctions alloc] init];
//        [_vdbfunctions InsertMediaFiles:file WithFileName:[file lastPathComponent] WithTotalChunk:(int)totalchunk AndStatus:NO];
//        
//        [self sendRequestToServer_fileName:[file lastPathComponent]];
        /*------------------------ */
        scribImgFile=file;
        
        
    
    }
  
    else if((![file length] > 0) && drawEventOccurred) //EDIT  MODE
    {
        iseditMode=NO;
        isImageSaved=YES;
        drawEventOccurred=NO;
        
//        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Message" message:@"Edit Mode" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//        [alert show];
//            [self removeImage:file];
        
//        [self updateArrayAndPlist];
        
        UIImageWriteToSavedPhotosAlbum([self imageRepresenation], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        
        //    CGSize newSize = CGSizeMake(320, 427);
        CGSize newSize = CGSizeMake(480, 480);
        UIGraphicsBeginImageContext( newSize );// a CGSize that has the size you want
        [[self imageRepresenation] drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
        //image is the original UIImage
        UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        ////remove above this line once the 8192 problem is fixed
        
        //store the image as a jpeg file
        NSData *imD = [NSData dataWithData:UIImageJPEGRepresentation(newImage, 1.0f)];
        if (bgImageView.image!=nil)
        {
            NSMutableString *filePath = [[NSMutableString alloc] initWithFormat:@"%@", [VSCore getImagesFolder]];
            NSMutableString *filename = [NSMutableString stringWithFormat:@"%@.jpg",[VSCore getUniqueFileName]];
            file = [filePath stringByAppendingPathComponent:filename];
            if (![imD writeToFile:file atomically:YES])
            {
                NSLog (@"There was a problem writing the image %@", file);
            }
            scribImgFile=file;


        }
       
        
//        /*-----Calculate Total chunk of the image and save Into Database ----*/
//        
//        NSData *fileData = [NSData dataWithContentsOfFile:file];
//        
//        NSUInteger length = [fileData length];
//        //  NSUInteger chunkSize = 1024 * 1024 *2; // chunk size is 2MB
//        NSUInteger chunkSize = 1024 * 1024 *1;
//        NSInteger totalchunk=  length/chunkSize;
//        //   NSInteger currentchunk = 1;
//        
//        if(length % chunkSize != 0)
//        {
//            totalchunk = totalchunk+1;
//        }
//        
//        NSLog(@"total chunk is %ld", (long)totalchunk);
//        
//        VDBFunctions *_vdbfunctions=[[VDBFunctions alloc] init];
//        [_vdbfunctions InsertMediaFiles:file WithFileName:[file lastPathComponent] WithTotalChunk:(int)totalchunk AndStatus:NO];
//        
//        [self sendRequestToServer_fileName:[file lastPathComponent]];
//        /*------------------------ */

    }else if([file length]>0)
    {
        scribImgFile=file;
    }
    if ([file length]>0) {
        
        [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:file]];

    }
    [self dismissViewControllerAnimated:YES completion:NULL];

    
}

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}


- (void)removeImage:(NSString *)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
//    NSString *filePath = [[VSCore getImagesFolder] stringByAppendingPathComponent:fileName];
    NSError *error;
    BOOL success = [fileManager removeItemAtPath:filePath error:&error];
    if (success)
    {
         NSLog(@"Succesfully Deleted file ");
    }

    else
    {
        NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
    }
}

//-(void)updateArrayAndPlist
//{
//    NSMutableArray *myartArray=[[[kidInfoDict objectForKey:@"myart"] componentsSeparatedByString:@";"] mutableCopy];
//    
//    if ([myartArray count] > 0)
//    {
//        [myartArray removeObject:file];
//        
//        [kidInfoDict removeObjectForKey:@"myart"];
//        [kidInfoDict setObject:[myartArray componentsJoinedByString:@";"] forKey:@"myart"];
//
//    }
//    
//}
//

//-(void)sendRequestToServer_fileName:(NSString *)fileName
//
//{
//    NSString *KidToken=nil;
//    
//    if ([kidInfoDict objectForKey:@"cookie"] != nil)
//    {
//        KidToken=[[kidInfoDict objectForKey:@"cookie"] objectForKey:@"value"];
//    }
//    else
//    {
//        KidToken=[kidInfoDict objectForKey:@"KidsToken"];
//    }
//    
//    NSMutableString *payload= [[NSMutableString alloc]initWithFormat:@"<ScribbleAppRequest><ClientRequest><request type=\"authenticate\"><formname>frm_newart</formname><action>btn_submit</action><phoneinfo><ostype>iphone</ostype><versionNo>6.1.1</versionNo><buildno></buildno></phoneinfo><kidstoken><![CDATA[%@]]></kidstoken><token><![CDATA[%@]]></token><filename><![CDATA[%@]]></filename></request></ClientRequest></ScribbleAppRequest>", KidToken, [[NSUserDefaults standardUserDefaults] objectForKey:@"token"], fileName] ;
//
//    NSLog(@"Request : %@", payload);
//    
//    WebService *webservices = [[WebService alloc]init];
//    [webservices SendDataToServer:payload toURI:RURL];
//    
//    ResponseParser *_responseParser=[ResponseParser getInstance];
//    [_responseParser setResponseDelegate:self];
//    
//
//}

-(void)browsePics
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:NULL];

}

-(void)insertStickers
{
    UIView *darkView = [[UIView alloc] initWithFrame:self.view.bounds];
    darkView.alpha = 0.3;
    darkView.backgroundColor = [UIColor blackColor];
    darkView.tag = 36;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissView)];
    [darkView addGestureRecognizer:tapGesture];
    [self.view addSubview:darkView];
    
    //ramya added
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        // The device is an iPad running iOS 3.2 or later.
        _scrollView=[[UIScrollView alloc] initWithFrame:CGRectMake(0,835,768,91)];

    }
    else
    {
        // The device is an iPhone or iPod touch.
//        _scrollView=[[UIScrollView alloc] initWithFrame:CGRectMake(5, 403, 310, 91)];
        _scrollView=[[UIScrollView alloc] initWithFrame:CGRectMake(5, result.height-165, result.width-10, 91)];


    }
    
    _scrollView.scrollEnabled=YES;
    _scrollView.pagingEnabled=YES;
    
    //adding BackGround image to UISCrollView
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:_scrollView.frame];
//    imageView.image =[UIImage imageNamed:@"brushbg.png"] ;
    imageView.image =[UIImage imageNamed:@"Plain.png"] ;

    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:imageView];
    imageView.tag=35;
    [_scrollView setBackgroundColor:[UIColor clearColor]];
    
    [self.view addSubview:_scrollView];
    
    [VSCore copyPlistFileFromMainBundle:@"Stickers" ToDocumentPath:@"Stickers_M"];
    
    NSMutableString *plistPath = [[VSCore getPlistPath:@"Stickers_M"] mutableCopy];
    
    
    NSArray *arrayData=[[NSArray alloc] initWithContentsOfFile:plistPath];
    
    for (int i=1; i <= [arrayData count]; i++)
    {
        
        NSDictionary *dict=[arrayData objectAtIndex:i-1];
        
        UIImageView *imgView =[[UIImageView alloc] init];
        //  self.imgView = [[UIImageView alloc] init];
        _tapgesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedgestureforStickers:)];
        [imgView addGestureRecognizer:_tapgesture];
        [imgView setMultipleTouchEnabled:YES];
        [imgView setUserInteractionEnabled:YES];
        [ imgView.layer setBorderColor: [[UIColor whiteColor] CGColor]];
        [imgView.layer setBorderWidth: 2.0];
        
        [imgView setImage:[UIImage imageNamed:[dict objectForKey:@"Name"]]];
        
        CGRect rectt = imgView.frame;
        rectt.size.height = 90;
        rectt.size.width = 100; //Divided by the number of UIButtons
        imgView.frame = rectt;
        imgView.tag=i;
        //        self.imgView.layer.cornerRadius = self.imgView.frame.size.height/2;
        //        self.imgView.layer.masksToBounds= YES;
        CALayer *imglayer=[imgView layer];
        [imglayer setCornerRadius:10];
        imglayer.masksToBounds=YES;
        
        [_scrollView addSubview:imgView];
        _scrollView.pagingEnabled=YES;
        
        [_scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
        
    }
    
    [self layoutScrollImages];
}


-(void)launchPageLayouts
{
    UIView *darkView = [[UIView alloc] initWithFrame:self.view.bounds];
    darkView.alpha = 0.3;
    darkView.backgroundColor = [UIColor blackColor];
    darkView.tag = 36;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissView)];
    [darkView addGestureRecognizer:tapGesture];
    [self.view addSubview:darkView];
    
    //ramya added
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        // The device is an iPad running iOS 3.2 or later.
        _scrollView=[[UIScrollView alloc] initWithFrame:CGRectMake(0,835,768,91)];

    }
    else
    {
//        _scrollView=[[UIScrollView alloc] initWithFrame:CGRectMake(5, 403, 310, 91)];
        _scrollView=[[UIScrollView alloc] initWithFrame:CGRectMake(5, result.height-165, result.width-10, 91)];
// The device is an iPhone or iPod touch.
    }
   
    _scrollView.scrollEnabled=YES;
    _scrollView.pagingEnabled=YES;
    
    //adding BackGround image to UISCrollView
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:_scrollView.frame];
//    imageView.image =[UIImage imageNamed:@"brushbg.png"] ;
     imageView.image =[UIImage imageNamed:@"Plain.png"] ;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:imageView];
    imageView.tag=35;
    [_scrollView setBackgroundColor:[UIColor clearColor]];
    
    [self.view addSubview:_scrollView];
    
    [VSCore copyPlistFileFromMainBundle:@"PageLayouts" ToDocumentPath:@"PageLayouts_M"];
    
    NSMutableString *plistPath = [[VSCore getPlistPath:@"PageLayouts_M"] mutableCopy];
    
    
    NSArray *arrayData=[[NSArray alloc] initWithContentsOfFile:plistPath];
    
    for (int i=1; i <= [arrayData count]; i++)
    {
        
        NSDictionary *dict=[arrayData objectAtIndex:i-1];
        
        UIImageView *imgView =[[UIImageView alloc] init];
        //  self.imgView = [[UIImageView alloc] init];
        _tapgesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedgestureforPageLayouts:)];
        [imgView addGestureRecognizer:_tapgesture];
        [imgView setMultipleTouchEnabled:YES];
        [imgView setUserInteractionEnabled:YES];
        [ imgView.layer setBorderColor: [[UIColor whiteColor] CGColor]];
        [imgView.layer setBorderWidth: 2.0];
        
        [imgView setImage:[UIImage imageNamed:[dict objectForKey:@"Name"]]];
        
        CGRect rectt = imgView.frame;
        rectt.size.height = 90;
        rectt.size.width = 100; //Divided by the number of UIButtons
        imgView.frame = rectt;
        imgView.tag=i;
        //        self.imgView.layer.cornerRadius = self.imgView.frame.size.height/2;
        //        self.imgView.layer.masksToBounds= YES;
        CALayer *imglayer=[imgView layer];
        [imglayer setCornerRadius:10];
        imglayer.masksToBounds=YES;
        
        [_scrollView addSubview:imgView];
        _scrollView.pagingEnabled=YES;
        
        [_scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
        
    }
    
    [self layoutScrollImages];
}

-(void)dismissView
{
//    [[[self view] viewWithTag:9] removeFromSuperview];
    [[[self view] viewWithTag:36] removeFromSuperview];
    [[[self view] viewWithTag:35] removeFromSuperview];
    [_scrollView removeFromSuperview];
}
-(IBAction)goBack:(id)sender
{
    if (drawEventOccurred)
    {
        [self showSimple:nil withbuttonTitle:@" Discard " andMessage:@"Scribbling has not been saved.Do you want to save or discard it?"];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)showSimple:(UIView *)anchor withbuttonTitle:(NSString*)title andMessage:(NSString*)_message{
    //This is am example of an action sheet that is reused!
        _simple = [JGActionSheet actionSheetWithSections:@[[JGActionSheetSection sectionWithTitle:@"" message:_message buttonTitles:@[@" Save ", title] buttonStyle:JGActionSheetButtonStyleGreen], [JGActionSheetSection sectionWithTitle:nil message:nil buttonTitles:@[@"Cancel"] buttonStyle:JGActionSheetButtonStyleGreen]]];
        
//        [_simple setButtonStyle:JGActionSheetButtonStyleGreen forButtonAtIndex:1];

        _simple.delegate = self;
        
        _simple.insets = UIEdgeInsetsMake(20.0f, 0.0f, 0.0f, 0.0f);
        
//        if (iPad) {
//            [_simple setOutsidePressBlock:^(JGActionSheet *sheet) {
//                [sheet dismissAnimated:YES];
//            }];
//        }
        
         [_simple setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath)
         {
             if (indexPath.section == 0)
             {
                 if (indexPath.row == 0)
                 {
                     [self saveImageAndSendtoServer];

                 }
                 
                 else
                 {
                     if ([title isEqualToString:@"New Scribbling"])
                     {
                         [self eraseView];
                         drawEventOccurred=NO;
                     }
                     else
                     [self dismissViewControllerAnimated:YES completion:nil];

                 }
             }
             
                [sheet dismissAnimated:YES];
        }];
    
    
    [_simple showInView:self.view animated:YES];

}

-(UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
	if (motion == UIEventSubtypeMotionShake )
	{
		// User was shaking the device. Post a notification named "shake".
		[[NSNotificationCenter defaultCenter] postNotificationName:@"shake" object:self];
	}
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
}

-(void)chooseBrushes_clicked
{
   /*Set the default brush color after using an eraser */
    
    if (drawingView.isEraseMode)
    {
        CGColorRef coloref = [colorPickerView.color CGColor];
        
        const CGFloat* components = CGColorGetComponents(coloref);
        
        CGFloat red = components[0];
        CGFloat green = components[1];
        CGFloat blue = components[2];
        // Defer to the OpenGL view to set the brush color
        [drawingView setBrushColorWithRed:red green:green blue:blue];
        drawingView.isEraseMode=NO;
    }
    
    UIView *darkView = [[UIView alloc] initWithFrame:self.view.bounds];
    darkView.alpha = 0.3;
    darkView.backgroundColor = [UIColor blackColor];
    darkView.tag = 36;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissView)];
    [darkView addGestureRecognizer:tapGesture];
    [self.view addSubview:darkView];
//ramya added
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        // The device is an iPad running iOS 3.2 or later.
        _scrollView=[[UIScrollView alloc] initWithFrame:CGRectMake(0,835,768,91)];

    }
    else
    {
        // The device is an iPhone or iPod touch.
//        _scrollView=[[UIScrollView alloc] initWithFrame:CGRectMake(5, 405, 310, 91)];
        _scrollView=[[UIScrollView alloc] initWithFrame:CGRectMake(5, result.height-165, result.width-10, 91)];


    }
    
    
    _scrollView.scrollEnabled=YES;
    _scrollView.pagingEnabled=YES;
    
    //adding BackGround image to UISCrollView
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:_scrollView.frame];
//    imageView.image =[UIImage imageNamed:@"brushbg.png"] ;
    imageView.image =[UIImage imageNamed:@"Plain.png"] ;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:imageView];
    imageView.tag=35;
    [_scrollView setBackgroundColor:[UIColor clearColor]];

    [self.view addSubview:_scrollView];
    
    [VSCore copyPlistFileFromMainBundle:@"BrushePatterns" ToDocumentPath:@"BrushePatterns_M"];

    NSMutableString *plistPath = [[VSCore getPlistPath:@"BrushePatterns_M"] mutableCopy];

    
    NSArray *arrayData=[[NSArray alloc] initWithContentsOfFile:plistPath];
    
    for (int i=1; i <= [arrayData count]; i++)
    {

        NSDictionary *dict=[arrayData objectAtIndex:i-1];
        
        UIImageView *imgView =[[UIImageView alloc] init];
        //  self.imgView = [[UIImageView alloc] init];
        _tapgesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedgesture:)];
        [imgView addGestureRecognizer:_tapgesture];
        [imgView setMultipleTouchEnabled:YES];
        [imgView setUserInteractionEnabled:YES];
        [ imgView.layer setBorderColor: [[UIColor whiteColor] CGColor]];
        [imgView.layer setBorderWidth: 2.0];

        [imgView setImage:[UIImage imageNamed:[dict objectForKey:@"BrushImage"]]];

        CGRect rectt = imgView.frame;
        rectt.size.height = 78;
        rectt.size.width = 100; //Divided by the number of UIButtons
        imgView.frame = rectt;
        imgView.tag=i;
        //        self.imgView.layer.cornerRadius = self.imgView.frame.size.height/2;
        //        self.imgView.layer.masksToBounds= YES;
        CALayer *imglayer=[imgView layer];
        [imglayer setCornerRadius:10];
        imglayer.masksToBounds=YES;
        
        [_scrollView addSubview:imgView];
        _scrollView.pagingEnabled=YES;
        
        [_scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
        
    }
    
    [self layoutScrollImages];
}

-(void) layoutScrollImages
{
	UIImageView *view = nil;
	NSArray *subviews = [_scrollView subviews];
    
	// reposition all image subviews in a horizontal serial fashion
	CGFloat curXLoc = 0;
	for (view in subviews)
	{
		if ([view isKindOfClass:[UIImageView class]] && view.tag > 0)
		{
			CGRect frame = view.frame;
			frame.origin = CGPointMake(curXLoc, 3);
			view.frame = frame;
			
            //	curXLoc += (100);
            // curXLoc += (102);
            curXLoc += view.frame.size.width + 4 ;
            
		}
        
	}
    
    [_scrollView setContentSize:CGSizeMake(([subviews count] * 85), [_scrollView bounds].size.height)];
}


-(void) layoutScrollImagesForScribbling
{
    UIImageView *view = nil;
    NSArray *subviews = [_scrollView subviews];
    
    // reposition all image subviews in a horizontal serial fashion
    CGFloat curXLoc = 0;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
          curXLoc = 30;
    }
    for (view in subviews)
    {
        if ([view isKindOfClass:[UIImageView class]] && view.tag > 0)
        {
            if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                CGRect frame = view.frame;
                frame.origin = CGPointMake(curXLoc, 3);
                view.frame = frame;
                
                //	curXLoc += (100);
                // curXLoc += (102);
                curXLoc += view.frame.size.width + 50 ;
            }else{
                CGRect frame = view.frame;
                frame.origin = CGPointMake(curXLoc, 3);
                view.frame = frame;
                
                //	curXLoc += (100);
                // curXLoc += (102);
                curXLoc += view.frame.size.width + 10 ;
            }
                
           
            
        }
        
    }
    
    [_scrollView setContentSize:CGSizeMake(([subviews count] * 45), [_scrollView bounds].size.height)];
}

-(void) tappedgestureForScribbling:(UITapGestureRecognizer*)sender
{
    NSMutableString *plistPath = [[VSCore getPlistPath:@"ScribblingIcons_M"] mutableCopy];
    
    NSArray *arrayData=[[NSArray alloc] initWithContentsOfFile:plistPath];
    
    for (int i=1; i <= [arrayData count]; i++)
    
    {
//        ((UIImageView *)sender.view).image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name1"]];
        
        if (((UIImageView *)sender.view).tag==i)
        {
            
        switch (i) {
                
            case 1:
                
                ((UIImageView *)sender.view).image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name1"]];
                [self erase_view];
                break;
                
            case 2:
                
                ((UIImageView *)sender.view).image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name1"]];
                [self undoBtn_Clicked];

                break;
            
            
            case 3:
                
                ((UIImageView *)sender.view).image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name1"]];
                [self redoBtn_clciked];

                break;
            
            case 4:
                
                ((UIImageView *)sender.view).image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name1"]];
                [self launch_colorPicker];

                break;
           
            case 5:
                
                ((UIImageView *)sender.view).image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name1"]];
                [self chooseBrushes_clicked];

                break;
            
            case 6:
                
                ((UIImageView *)sender.view).image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name1"]];
                 [self browsePics];

                break;
            
            case 7:
                ((UIImageView *)sender.view).image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name1"]];
                [self saveImage];

                break;
                
            
            case 8:
                
                ((UIImageView *)sender.view).image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name1"]];
                 [self launchEraser];
                break;
            
            
            case 9:
                
                ((UIImageView *)sender.view).image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name1"]];
               [self launchPageLayouts];

                break;
                
            
            
        default:
                ((UIImageView *)sender.view).image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name1"]];
                [self erase_view];

                break;
        }
            
            
        }else{
            if (i==1) {
                UIImageView *img= [[self view]viewWithTag:1];
                img.image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name"]];
            }else if (i==2)
            {
                UIImageView *img= [[self view]viewWithTag:2];
                img.image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name"]];
            }else if (i==3)
            {
                UIImageView *img= [[self view]viewWithTag:3];
                img.image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name"]];
            }else if (i==4)
            {
                UIImageView *img= [[self view]viewWithTag:4];
                img.image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name"]];
            }else if (i==5)
            {
                UIImageView *img= [[self view]viewWithTag:5];
                img.image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name"]];
            }else if (i==6)
            {
                UIImageView *img= [[self view]viewWithTag:6];
                img.image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name"]];
            }else if (i==7)
            {
                UIImageView *img= [[self view]viewWithTag:7];
                img.image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name"]];
            }else if (i==8)
            {
                UIImageView *img= [[self view]viewWithTag:8];
                img.image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name"]];
            }else
            {
                UIImageView *img= [[self view]viewWithTag:9];
                img.image=[UIImage imageNamed:[[arrayData objectAtIndex:i-1] objectForKey:@"Name"]];
            }
            
            
        }
    }
}

-(void) tappedgesture:(UITapGestureRecognizer*)sender
{
    NSMutableString *plistPath = [[VSCore getPlistPath:@"BrushePatterns_M"] mutableCopy];
    
    NSArray *arrayData=[[NSArray alloc] initWithContentsOfFile:plistPath];

    for (int i=1; i <= [arrayData count]; i++)
    {
        if (((UIImageView *)sender.view).tag==i)
        {
            
            NSMutableString *brushName = [[arrayData objectAtIndex:i-1] objectForKey:@"BrushName"];

            [drawingView setUpBrush_withImagename:brushName];
            
            break;
        }

    }
    
    [self dismissView];
}

-(void) tappedgestureforStickers:(UITapGestureRecognizer*)sender
{
    NSMutableString *plistPath = [[VSCore getPlistPath:@"Stickers_M"] mutableCopy];
    
    NSArray *arrayData=[[NSArray alloc] initWithContentsOfFile:plistPath];
    
    for (int i=1; i <= [arrayData count]; i++)
    {
        if (((UIImageView *)sender.view).tag==i)
        {
            
            NSMutableString *_stickerName = [[arrayData objectAtIndex:i-1] objectForKey:@"Image"];
            
            [drawingView setStickerName:_stickerName];
            [drawingView setIsStickersMode:YES];
            
            break;
        }
        
    }
    
    [self dismissView];
}

-(void) tappedgestureforPageLayouts:(UITapGestureRecognizer*)sender
{
    NSMutableString *plistPath = [[VSCore getPlistPath:@"PageLayouts_M"] mutableCopy];
    
    NSArray *arrayData=[[NSArray alloc] initWithContentsOfFile:plistPath];
    
    for (int i=1; i <= [arrayData count]; i++)
    {
        if (((UIImageView *)sender.view).tag==i)
        {
//            //prasuna add this condition
//            if(drawEventOccurred&&![file isEqualToString:@""])
//            {
//            //end here...
                NSMutableString *_layoutName = [[arrayData objectAtIndex:i-1] objectForKey:@"Image"];
                [bgImageView setImage:[UIImage imageNamed:_layoutName]];
                drawEventOccurred=YES;
                break;

//            }else
//            {
//                UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:@"Message" message:@"User should draw first" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
//                [alertview show];
//            }
            
        }
        
    }
    
    [self dismissView];
}



-(void)launch_colorPicker
{

    UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    overlay.alpha = 0.7;
    overlay.backgroundColor = [UIColor blackColor];
    overlay.tag = 37;
    [self.view addSubview:overlay];
    
    //ADD TAP GESTURE RECOGNIZER
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideAllViews:)];
    [overlay addGestureRecognizer:gestureRecognizer];
//    gestureRecognizer.cancelsTouchesInView = NO;  // this prevents the gesture recognizers to 'block' touches
    gestureRecognizer.numberOfTapsRequired=1;
    gestureRecognizer.delegate = self;

    colorPickerView.color = _color;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        // The device is an iPad running iOS 3.2 or later.
        colorPickerView.frame=CGRectMake(22,180,735,700);

    }
    else
    {
        // The device is an iPhone or iPod touch.
        colorPickerView.frame=CGRectMake(0, 170, result.width, result.height-160);

    }
    
    
    colorPickerView.brightnessSlider.hidden=YES;
    colorPickerView.colorInfoView.hidden=YES;
    colorPickerView.backgroundColor=[UIColor clearColor];
    colorPickerView.color=[UIColor blueColor];
    
    [self.view addSubview:colorPickerView];
}

-(void)hideAllViews:(UITapGestureRecognizer *)sender
{
//    CGPoint tapPoint = [sender locationInView:colorPickerView];
//    int tapX = (int) tapPoint.x;
//    int tapY = (int) tapPoint.y;
    
//    NSLog(@"TAPPED X:%d Y:%d", tapX, tapY);
    
   
        CGColorRef coloref = [colorPickerView.color CGColor];
        const CGFloat* components = CGColorGetComponents(coloref);
        
        CGFloat red = components[0];
        CGFloat green = components[1];
        CGFloat blue = components[2];
        //    CGFloat alpha =1;
        //    UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
        [drawingView setBrushColorWithRed:red green:green blue:blue];
    
    [[self.view viewWithTag:37] removeFromSuperview];
        [colorPickerView removeFromSuperview];
    

}

//-(IBAction)erase_view:(id)sender
//{
//    if (drawEventOccurred)
//    {
//        [self showSimple:nil withbuttonTitle:@"New Scribbling" andMessage:@"Scribbing has not been saved.Do you want to save or create a new one?"];
//    }
//    
//    else
//    {
//        
//        [drawingView erase];
//        drawEventOccurred=NO;
//        iseditMode=NO;
//        file=@"";
//        //    [shareArtButton setEnabled:NO];
//    }
//   
//}

-(IBAction)onMore_clicked:(id)sender
{
    [popUp show];
}

-(void)launchEraser
{
   
    CGColorRef coloref = [[UIColor whiteColor] CGColor];
    
//    const CGFloat* components = CGColorGetComponents(coloref);
    
    CGFloat red = 255.0;
    CGFloat green = 255.0;
    CGFloat blue = 255.0;
	// Defer to the OpenGL view to set the brush color
    drawingView.isEraseMode=YES;
    [drawingView setBrushColorWithRed:red green:green blue:blue];

}

-(UIImage*) imageRepresenation
{
    UIImage* blendedImage=nil;
    UIImageView* imageView = [[UIImageView alloc] initWithFrame:bgImageView.frame];
    imageView.image=bgImageView.image;
    imageView.contentMode=bgImageView.contentMode;
    
    UIImageView* subView   = [[UIImageView alloc] initWithImage:[drawingView imageRepresentation]];
    [imageView addSubview:subView];
    UIGraphicsBeginImageContext(imageView.frame.size);
    [imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    blendedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    subView=nil;
    imageView=nil;
    return blendedImage;
}


#pragma mark - Image Picker Controller delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
//    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    
    [bgImageView setImage:[UIImage imageNamed:@"Plain.png"]];
    
    
    
    //prasuna commentted and add below  code
    
//    UIImage *myIcon = [VSCore imageWithImage:info[UIImagePickerControllerEditedImage] scaledToSize:CGSizeMake(result.width, result.height-88)];
//
//    UIView* imageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 512, 512)];
//    
//    UIImageView* subView   = [[UIImageView alloc] initWithImage:myIcon];
//    
//    [imageView addSubview:subView];
////    [subView release];
//    subView=NULL;
//    UIImage* blendedImage =nil;
//    
//    UIGraphicsBeginImageContext(imageView.frame.size);
//    
//    [imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
//    
//    blendedImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    
//    [imageView release];
//    imageView=NULL;
    
    
//    [drawingView mergeWithImage:blendedImage];

    
    
    
    
    if ([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.image"])
    {
        
            UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
//         UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
         //        CGSize newSize = CGSizeMake(320, 427);
         CGSize newSize = CGSizeMake(chosenImage.size.width, chosenImage.size.height);
         
         UIGraphicsBeginImageContext( newSize );// a CGSize that has the size you want
         [chosenImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
         //image is the original UIImage
         UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
         UIGraphicsEndImageContext();
//            [bgImageView setImage:newImage];
//          bgImageView.contentMode = UIViewContentModeScaleAspectFit;
//        
        NSData *imD = [NSData dataWithData:UIImageJPEGRepresentation(newImage, 1.0f)];
        
        NSMutableString *filePath = [[NSMutableString alloc] initWithFormat:@"%@", [VSCore getImagesFolder]];
        NSMutableString *filename = [NSMutableString stringWithFormat:@"%@.jpg",[VSCore getUniqueFileName]];
        NSString *file1 = [filePath stringByAppendingPathComponent:filename];
        if (![imD writeToFile:file1 atomically:YES])
        {
            //DLog (@"There was a problem writing the image %@", file);
        }
        drawingView.isEditMode=YES;
        drawingView.savedArtWorkimagePath=file1;
        
    }
    

    drawEventOccurred=YES;
    /*CGSize newSize = CGSizeMake(320, 427);
    UIGraphicsBeginImageContext( newSize );// a CGSize that has the size you want
    [chosenImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    //image is the original UIImage
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    ////remove above this line once the 8192 problem is fixed
    
    //store the image as a jpeg file
    NSData *imD = [NSData dataWithData:UIImageJPEGRepresentation(newImage, 1.0f)];
    
    NSMutableString *filePath = [[NSMutableString alloc] initWithFormat:@"%@", [VSCore getImagesFolder]];
    NSMutableString *filename = [NSMutableString stringWithFormat:@"%@.jpg",[VSCore getUniqueFileName]];
    NSString *file = [filePath stringByAppendingPathComponent:filename];
    
    if (![imD writeToFile:file atomically:YES])
    {
        //DLog (@"There was a problem writing the image %@", file);
    }
    
    //
    //    if (ANTDViewDelegate && [ANTDViewDelegate respondsToSelector:@selector(updateIconViewforSelectedrow:withImage:)])
    //    {
    //        [ANTDViewDelegate updateIconViewforSelectedrow:2 withImage:file];
    //    }
    
     */
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    [self.navigationController popToRootViewControllerAnimated:YES];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

//-(void)startAsyncRequest
//{
////    NSMutableString *asyncRequest = [[[NSBundle mainBundle] pathForResource:@"AsyncRequest" ofType:@"xml"] mutableCopy];
//
//    NSString *base64Encoded=[[NSString alloc] init];
//    NSMutableData *chunk=[[NSMutableData alloc]init];
//    NSUInteger length=0;
//    int totalChunk=0;
//    NSString *filePath=nil;
//    NSUInteger chunkSize=1024 * 1024 * 1;
//    NSString *_currentChunk=nil;
//    
//    NSUInteger offset=0;
//
//    //Get the filePath from DB based on fileName
//    VDBFunctions *_vdbfunctions=[[VDBFunctions alloc] init];
//    filePath=[_vdbfunctions GetFilePath:[file lastPathComponent]];
//    int _outgoingMsgID=[[_vdbfunctions SelectMsgId:[file lastPathComponent]]intValue];
//
//    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
//    length = [fileData length];
//    totalChunk=[[_vdbfunctions SelectTotalChunk:[file lastPathComponent]]intValue];
//    
//    int presentChunk=1;
//    
//    while (offset < length)
//    {
//        NSUInteger thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
//        _currentChunk =[[NSString alloc]initWithFormat:@"currentchunk=\"%d\"", presentChunk] ;
//        
//        chunk = [NSMutableData dataWithBytesNoCopy:(char *)[fileData bytes] + offset length:thisChunkSize freeWhenDone:NO];
//        base64Encoded = [[NSString alloc] initWithFormat:@"%@", [chunk base64Encoding]];
//        
//
//        NSString *KidToken=nil;
//        
//        if ([kidInfoDict objectForKey:@"cookie"] != nil)
//        {
//            KidToken=[[kidInfoDict objectForKey:@"cookie"] objectForKey:@"value"];
//        }
//        else
//        {
//            KidToken=[kidInfoDict objectForKey:@"KidsToken"];
//        }
//
//        NSMutableString *payload= [[NSMutableString alloc]initWithFormat:@"<UploadContents><ClientRequest><request type=\"authenticate\"><formname>frm_imageupload</formname><action>btn_imageupload</action><phoneinfo><ostype>iphone</ostype><versionNo>6.1.1</versionNo><buildno></buildno></phoneinfo><kidstoken><![CDATA[%@]]></kidstoken><token><![CDATA[%@]]></token><callbackURL>http://content.vaayoo.com/AppsPlatForm/JiJiScribble1_1/JijiScribleService.svc/UploadContentToVaayoo</callbackURL><type>1</type><filename><![CDATA[%@]]></filename><currentchunk><![CDATA[%d]]></currentchunk><totalchunk><![CDATA[%d]]></totalchunk><base64data><![CDATA[%@]]></base64data></request></ClientRequest></UploadContents>", KidToken, [[NSUserDefaults standardUserDefaults] objectForKey:@"token"], [filePath lastPathComponent] , presentChunk , totalChunk , base64Encoded] ;
//        
//        
//        [_vdbfunctions InsertIntoOutgoing :_outgoingMsgID WithCurrentChunk :presentChunk WithAsyncRequest:payload AndStatus:0];
//        offset += thisChunkSize;
//        presentChunk++;
//
//    }
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),
//                   ^{
//                       AsyncUploader *_asyncUploader=[[AsyncUploader alloc]init];
//                       [_asyncUploader setAsyncDelegate:self];
//                       [_asyncUploader uploadFilesfromOutgoingTable];
//
//                   });
//
//}
//
//#pragma ResponseParserDelegate Methods
//
//-(void)receivedSuccess:(NSDictionary *)_dict
//{
//    
//    [ProgressHUD showSuccess:@"Saved" Interaction:YES];
//    
//    isArtWorkSaved=YES;
//    
//    //if received Success then save the Art into the plist
//    
//    if  (!iseditMode)
//    {
//        NSMutableString *plistPath = [[VSCore getPlistPath:@"KidsProfiles_M"] mutableCopy];
//        NSMutableArray *profilesArray=[NSMutableArray arrayWithContentsOfFile:plistPath];
//        
//        NSMutableDictionary *tempDict=[profilesArray objectAtIndex:[[kidInfoDict objectForKey:@"ObjectIndex"] intValue]];
//        
//        if ([[tempDict objectForKey:@"myart"] length] > 0)
//        {
//            [tempDict setObject:[[tempDict objectForKey:@"myart"] stringByAppendingFormat:@";%@",file] forKey:@"myart"];
//        }
//        else
//        {
//            [tempDict setObject:file forKey:@"myart"];
//            
//        }
//        
//        [profilesArray writeToFile:plistPath atomically:YES];
//        
//        iseditMode=NO;
//    }
//   
//    [self startAsyncRequest];
//    //Start Async Request
//    
//}
//
//-(void)receivedFail
//{
//    
//}
//
//-(void)ParsedResponseWithCtrlDict:(NSMutableDictionary *)dict andResponseParser:(ResponseParser *)_responseParser
//{
//    
//}

#pragma AsyncUploaderDelegate Methods

-(void)UploadedLastchunkData_forFileName:(NSString *)_fileName
{
    if ([_fileName isEqualToString:[file lastPathComponent]])
    {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            //[shareArtButton setEnabled:YES];
        });
    }
   
}

#pragma mark PaintingViewDelegate Methods

-(void)touchesReceivedFor_DrawingView
{
    [_undoButton setEnabled:YES];
    [_redoButton setEnabled:YES];
    
    NSLog(@"Drawing Event Happened");
    drawEventOccurred=YES;
    drawCount++;
    undoCount=0;
    
    [self saveImageforeveryDrawEventOccured];

//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),
//                   ^{
//                   });
}



#pragma mark prasuna code

-(void)undoBtn_Clicked
{
    if (undoCount == 0)
    {
        undoCount=drawCount;
        
        if(undoCount == 1)
        {
            [_undoButton setEnabled:NO];
            [_redoButton setEnabled:NO];
            
            NSLog(@"Last round for Undo operation");
            drawEventOccurred=NO;
            //undoCount --;
            NSString *undoRedoPath = [[VSCore getUndoRedoFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.jpg",undoCount]];
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:undoRedoPath];
            if (fileExists)
            {
                NSLog(@"FileExists");
                drawingView.isEditMode=YES;
                drawingView.savedArtWorkimagePath=undoRedoPath;
                [drawingView layoutSubviews];
                drawingView.isEditMode=NO;
                [drawingView erase];
                
            }
            
            [self deleteFilesfromUndoRedoFloder];
            drawCount=0;
        }else{
        undoCount--;
        NSString *undoRedoPath = [[VSCore getUndoRedoFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.jpg",undoCount]];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:undoRedoPath];
        if (fileExists)
        {
            NSLog(@"FileExists");
            drawingView.isEditMode=YES;
            drawingView.savedArtWorkimagePath=undoRedoPath;
            [drawingView layoutSubviews];
            drawingView.isEditMode=NO;
        }
        }
    }
    else if(undoCount == 1)
    {
        [_undoButton setEnabled:NO];
        [_redoButton setEnabled:NO];
        
        NSLog(@"Last round for Undo operation");
        drawEventOccurred=NO;
        //undoCount --;
        NSString *undoRedoPath = [[VSCore getUndoRedoFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.jpg",undoCount]];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:undoRedoPath];
        if (fileExists)
        {
            NSLog(@"FileExists");
            drawingView.isEditMode=YES;
            drawingView.savedArtWorkimagePath=undoRedoPath;
            [drawingView layoutSubviews];
            drawingView.isEditMode=NO;
            [drawingView erase];
            
        }
        
        [self deleteFilesfromUndoRedoFloder];
        drawCount=0;
    }
    
    else
    {
        undoCount --;
        NSString *undoRedoPath = [[VSCore getUndoRedoFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.jpg",undoCount]];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:undoRedoPath];
        if (fileExists)
        {
            NSLog(@"FileExists");
            drawingView.isEditMode=YES;
            drawingView.savedArtWorkimagePath=undoRedoPath;
            [drawingView layoutSubviews];
            drawingView.isEditMode=NO;
        }
        
    }
}
-(void)redoBtn_clciked
{
    if (undoCount == drawCount)
    {
        NSLog(@"No artwork to perform REDO");
    }
    else
    {
        undoCount++;
        NSString *undoRedoPath = [[VSCore getUndoRedoFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.jpg",undoCount]];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:undoRedoPath];
        if (fileExists)
        {
            NSLog(@"FileExists");
            drawingView.isEditMode=YES;
            drawingView.savedArtWorkimagePath=undoRedoPath;
            [drawingView layoutSubviews];
            drawingView.isEditMode=NO;
        }
        
    }
    
}
-(void)erase_view
{
    if (drawEventOccurred)
    {
        [self showSimple:nil withbuttonTitle:@"New Scribbling" andMessage:@"Scribbling has not been saved.Do you want to save or create a new one?"];
    }
    
    else
    {
        
        if (scribImgFile!=nil)
        {
            UIAlertView *alter=[[UIAlertView alloc]initWithTitle:@"Message" message:@"The previous scribble image will be lost" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"NO",nil];
            [alter show];
            
            
        }else
        {
            [bgImageView setImage:[UIImage imageNamed:@"Plain.png"]];
            [drawingView erase];
            drawEventOccurred=NO;
            iseditMode=NO;
            file=@"";
            //    [shareArtButton setEnabled:NO];
        }
        
        
    }
    
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex==0) {
        [bgImageView setImage:[UIImage imageNamed:@"Plain.png"]];
        [drawingView erase];
        drawEventOccurred=NO;
        iseditMode=NO;
        file=@"";
        scribblingDone =NO;
}
    
}
#pragma for drawing

@end
