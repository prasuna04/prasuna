//
//  KIdCanvasPage.h
//  JijiScribble
//
//  Created by Kavya Valavala on 7/21/14.
//  Copyright (c) 2014 Vaayoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PaintingView.h"
#import "SoundEffect.h"
#import "ViewController.h"
//#import "DiaryEntryPage.h"

@interface KIdCanvasPage : UIViewController <PaintingViewDelegate>

{
    
    
    @private
        // The pixel dimensions of the backbuffer
        GLint backingWidth;
        GLint backingHeight;
        
        EAGLContext *context;
        
        // OpenGL names for the renderbuffer and framebuffers used to render to this view
        GLuint viewRenderbuffer, viewFramebuffer;
        
        // OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist)
        GLuint depthRenderbuffer;
        
        GLuint	brushTexture;
        GLuint	_brushTexture[9];
        
        CGPoint	location;
        CGPoint	previousLocation;
        Boolean	firstTouch;
        Boolean needsErase;
        
        
        //new texture for adding images to view
        GLuint	stampTexture;
        //we use these to set back the state after we have added images
        float lastSetRed;
        float lastSetGreen;
        float lastSetBlue;
        CAEAGLLayer *eaglLayer;
        
        BOOL isStickersMode;
        BOOL isEditMode;
        BOOL isEraseMode;
        NSString *stickerName;
        NSString *savedArtWorkimagePath;

    
    
	PaintingView		*drawingView;
    
	SoundEffect			*erasingSound;
	SoundEffect			*selectSound;
	CFTimeInterval		lastTime;
    BOOL                iseditMode;
    NSString            *savedImagePath;
    UIButton            *shareArtButton;
//    IBOutlet            UIImageView  *bgImageView;
    IBOutlet            UIButton     *undoButton, *redoButton;
    IBOutlet  UINavigationBar *nav_titlebar;
}

@property (nonatomic, retain) IBOutlet PaintingView *drawingView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollImageView;
@property (nonatomic, strong) NSMutableDictionary   *kidInfoDict;
@property (nonatomic)         BOOL                  iseditMode;
@property (nonatomic, strong) NSString              *savedImagePath;
@property (nonatomic, strong) IBOutlet  UIButton    *shareArtButton;
@property (nonatomic, strong) IBOutlet  UIImageView *bgImageView;
@property (nonatomic, strong) IBOutlet  UIButton     *undoButton, *redoButton;

-(IBAction)launch_colorPicker:(id)sender;

@end
