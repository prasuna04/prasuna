/*
     File: PaintingView.m
 Abstract: The class responsible for the finger painting. The class wraps the 
 CAEAGLLayer from CoreAnimation into a convenient UIView subclass. The view 
 content is basically an EAGL surface you render your OpenGL scene into.
  Version: 1.11
 
*/

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import "VSCore.h"
#import "PaintingView.h"

//CLASS IMPLEMENTATIONS:

// A class extension to declare private methods
@interface PaintingView (private)


- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;

@end

@implementation PaintingView

@synthesize  location;
@synthesize  previousLocation , eaglLayer;
@synthesize isStickersMode , isEditMode;
@synthesize stickerName;
@synthesize vertexBuffers;
@synthesize savedArtWorkimagePath, ViewDelegate;

void ProviderReleaseData ( void *info, const void *data, size_t size ) {

	free((void*)data);
}

-(UIImage*) upsideDownImageRepresenation{

	
	int imageWidth = CGRectGetWidth([self bounds]);
	int imageHeight = CGRectGetHeight([self bounds]);
	
	//image buffer for export
	NSInteger myDataLength = imageWidth* imageHeight * 4;
	
	// allocate array and read pixels into it.
	GLubyte *tempImagebuffer = (GLubyte *) malloc(myDataLength);
    
    glReadPixels(0, 0, imageWidth, imageHeight, GL_RGBA, GL_UNSIGNED_BYTE, tempImagebuffer);
	
	
	
	// make data provider with data.		
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, tempImagebuffer, myDataLength, ProviderReleaseData);
	
	
	// prep the ingredients
	int bitsPerComponent = 8;
	int bitsPerPixel = 32;
	int bytesPerRow = 4 * imageWidth;
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
	
	CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
	
	
	// make the cgimage
	CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
	
	
	
	// then make the uiimage from that
	
	UIImage *  myImage =  [UIImage imageWithCGImage:imageRef] ;
	
	CGDataProviderRelease(provider);
	CGImageRelease(imageRef);
	CGColorSpaceRelease(colorSpaceRef);
    
    //make sure it is in the autorelease pool
//	[myImage retain] ;
	
    return myImage;
}



-(UIImage*) imageRepresentation{
	
	UIImageView* upsideDownImageView=[[UIImageView alloc] initWithImage: [self upsideDownImageRepresenation]];
    
	upsideDownImageView.transform=CGAffineTransformScale(upsideDownImageView.transform, 1, -1);
	
	UIView* container=[[UIView alloc] initWithFrame:upsideDownImageView.frame];
	[container addSubview:upsideDownImageView];
	UIImage* toReturn=nil;
    
	UIGraphicsBeginImageContext(container.frame.size);
	
	[container.layer renderInContext:UIGraphicsGetCurrentContext()];
	
	toReturn = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
//	[upsideDownImageView release];
//	[container release];
	return toReturn;
}


-(void) mergeWithImage:(UIImage*) image
{
	if(image==nil){
		return;
	}
		
	glPushMatrix();
	glColor4f(256,
			  256,
			  256,
			  1.0);
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	glGenTextures(1, &stampTexture);
	glBindTexture(GL_TEXTURE_2D, stampTexture);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); 
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	
	
    
	GLuint imgwidth = CGImageGetWidth(image.CGImage);
	GLuint imgheight = CGImageGetHeight(image.CGImage);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	void *imageData = malloc( imgheight * imgwidth * 4 );
	CGContextRef context2 = CGBitmapContextCreate( imageData, imgwidth, imgheight, 8, 4 * imgwidth, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );
	CGContextTranslateCTM (context2, 0, imgheight);
	CGContextScaleCTM (context2, 1.0, -1.0);
	CGColorSpaceRelease( colorSpace );
	CGContextClearRect( context2, CGRectMake( 0, 0, imgwidth, imgheight ) );
	CGContextTranslateCTM( context2, 0, imgheight - imgheight );
	CGContextDrawImage( context2, CGRectMake( 0, 0, imgwidth, imgheight ), image.CGImage );
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imgwidth, imgheight, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
	
	CGContextRelease(context2);
	
    
	free(imageData);
	
	static const GLfloat texCoords[] = {
		0.0, 1.0,
		1.0, 1.0,
		0.0, 0.0,
		1.0, 0.0
	};
	
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoords);   
	
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    /*
     
     These array would need to be changed if the size of the paintview changes. You must make sure that all image imput is 64x64, 256x256, 512x512 or 1024x1024.  In this we are using 512, but you can use 1024 as follows:
     
     use the numbers:
     {
     0.0, height, 0.0,
     1024, height, 0.0,
     0.0, height-1024, 0.0,
     1024, height-1024, 0.0
     }
     */
    
    
//    static const GLfloat vertices[] = {
//		0.0,  394, 0.0,
//		1024,  394, 0.0,
//		0.0, -630, 0.0,
//		1024, -630, 0.0
//	};
    
    
    static const GLfloat vertices[] = {
		0.0,  396, 0.0,
		512,  396, 0.0,
		0.0,  -32, 0.0,
		512,  -32, 0.0
        
//        0.0, 480, 0.0,
//        1024, 480, 0.0,
//        0.0,  -544, 0.0,
//        1024, -544, 0.0
	};
    
    //    static const GLfloat vertices[] = {
    //		0.25,  0.75 , 0.0,
    //		0.75 ,  0.75 , 0.0,
    //		0.25 , 0.25, 0.0,
    //        0.75,  0.25, 0.0
    //	};
    
	static const GLfloat normals[] = {
		0.0, 0.0, 512,
		0.0, 0.0, 512,
		0.0, 0.0, 512,
		0.0, 0.0, 512
	};

    
//	static const GLfloat normals[] = {
//		0.0, 0.0, 304,
//		0.0, 0.0, 304,
//		0.0, 0.0, 304,
//		0.0, 0.0, 304
//	};


	glBindTexture(GL_TEXTURE_2D, stampTexture);
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glNormalPointer(GL_FLOAT, 0, normals);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	glPopMatrix();

	glDeleteTextures( 1, &stampTexture );
	//set back the brush
	glBindTexture(GL_TEXTURE_2D, brushTexture);

	glColor4f(lastSetRed,
			  lastSetGreen,
			  lastSetBlue,
			  1.0);
	
	// Display the buffer
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
	
}

-(void) setImage:(UIImage*)newImage{
    
	[EAGLContext setCurrentContext:context];
	
	// Clear the buffer - but dont display it
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glClearColor(0.0, 0.0, 0.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT);
	
	[self loadSavedArtwork:newImage];
}


-(void) loadSavedArtwork:(UIImage*) image
{
	if(image==nil){
		return;
	}
	
    
    glPushMatrix();
	glColor4f(256,
			  256,
			  256,
			  1.0);
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	glGenTextures(1, &stampTexture);
	glBindTexture(GL_TEXTURE_2D, stampTexture);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	
	
    
	GLuint imgwidth = CGImageGetWidth(image.CGImage);
	GLuint imgheight = CGImageGetHeight(image.CGImage);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	void *imageData = malloc( imgheight * imgwidth * 4 );
	CGContextRef context2 = CGBitmapContextCreate( imageData, imgwidth, imgheight, 8, 4 * imgwidth, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );
    CGContextMoveToPoint(context2 , 180.0, 150.0);
	CGContextTranslateCTM (context2, 0, imgheight);
	CGContextScaleCTM (context2, 1.0, -1.0);
	CGColorSpaceRelease( colorSpace );
    
    //Change the values of CGContextClearRect & CGContextDrawImage for drawing at different points
	CGContextClearRect( context2, CGRectMake( 0, 0, imgwidth, imgheight ) );
	CGContextTranslateCTM( context2, 0, imgheight - imgheight );
	CGContextDrawImage( context2, CGRectMake( 0, 0, imgwidth, imgheight ), image.CGImage );
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imgwidth, imgheight, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
	
	CGContextRelease(context2);
	
    
	free(imageData);
	
	static const GLfloat texCoords[] = {
		0.0, 1.0,
		1.0, 1.0,
		0.0, 0.0,
		1.0, 0.0
	};
    
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
	
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    /*
     
     These array would need to be changed if the size of the paintview changes. You must make sure that all image imput is 64x64, 256x256, 512x512 or 1024x1024.  In this we are using 512, but you can use 1024 as follows:
     
     use the numbers:
     {
     0.0, height, 0.0,
     1024, height, 0.0,
     0.0, height-1024, 0.0,
     1024, height-1024, 0.0
     }
     */
    
    
    static const GLfloat vertices[] = {
		0.0,  396, 0.0,
		512,  396, 0.0,
		0.0, -32, 0.0,
		512, -32, 0.0
	};
    
    //    static const GLfloat vertices[] = {
    //		0.25,  0.75 , 0.0,
    //		0.75 ,  0.75 , 0.0,
    //		0.25 , 0.25, 0.0,
    //        0.75,  0.25, 0.0
    //	};
    
	static const GLfloat normals[] = {
		0.0, 0.0, 512,
		0.0, 0.0, 512,
		0.0, 0.0, 512,
		0.0, 0.0, 512
	};
    
	glBindTexture(GL_TEXTURE_2D, stampTexture);
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glNormalPointer(GL_FLOAT, 0, normals);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	glPopMatrix();
    
	glDeleteTextures( 1, &stampTexture );
	//set back the brush
	glBindTexture(GL_TEXTURE_2D, brushTexture);
    
	glColor4f(lastSetRed,
			  lastSetGreen,
			  lastSetBlue,
			  1.0);
	
	// Display the buffer
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
	
}

-(void) addStickersWithImage:(UIImage*) image atPoint:(CGPoint)point
{
    isStickersMode=YES;
    
	if(image==nil){
		return;
	}
	
    
    glPushMatrix();
	glColor4f(256,
			  256,
			  256,
			  1.0);
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	glGenTextures(1, &stampTexture);
	glBindTexture(GL_TEXTURE_2D, stampTexture);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	
    
	GLuint imgwidth = CGImageGetWidth(image.CGImage);
	GLuint imgheight = CGImageGetHeight(image.CGImage);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	void *imageData = malloc( imgheight * imgwidth * 4 );
	CGContextRef context2 = CGBitmapContextCreate( imageData, imgwidth, imgheight, 8, 4 * imgwidth, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );
    //    CGContextMoveToPoint(context2 , 180.0, 150.0);
    
	CGContextTranslateCTM (context2, 0, imgheight);
	CGContextScaleCTM (context2, 1.0, -1.0);
	CGColorSpaceRelease( colorSpace );
    
    //Change the values of CGContextClearRect & CGContextDrawImage for drawing at different points
	CGContextClearRect( context2, CGRectMake( location.x - 20, -location.y - 20, imgwidth, imgheight ) );
	CGContextTranslateCTM( context2, 0, imgheight - imgheight );
	CGContextDrawImage( context2, CGRectMake( location.x , -location.y, imgwidth, imgheight ), image.CGImage );
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imgwidth, imgheight, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
	
	CGContextRelease(context2);
	
    
	free(imageData);
	
	static const GLfloat texCoords[] = {
		0.0, 1.0,
		1.0, 1.0,
		0.0, 0.0,
		1.0, 0.0
	};
    
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
	
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    /*
     
     These array would need to be changed if the size of the paintview changes. You must make sure that all image imput is 64x64, 256x256, 512x512 or 1024x1024.  In this we are using 512, but you can use 1024 as follows:
     
     use the numbers:
     {
     0.0, height, 0.0,
     1024, height, 0.0,
     0.0, height-1024, 0.0,
     1024, height-1024, 0.0
     }
     */
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        static const GLfloat vertices[] = {
            //		0.0,  410, 0.0,
            //		410,  410, 0.0,
            //		0.0, -32, 0.0,
            //		410, -32, 0.0
            0.0,800, 0.0,
            800,800, 0.0,
            0.0,-20, 0.0,
            800,-20, 0.0
        };
        
        
        static const GLfloat normals[] = {
            0.0, 0.0, 735,//512 added ramya
            0.0, 0.0, 735,
            0.0, 0.0, 735,
            0.0, 0.0, 735
        };
        
        glBindTexture(GL_TEXTURE_2D, stampTexture);
        glVertexPointer(3, GL_FLOAT, 0, vertices);
        glNormalPointer(GL_FLOAT, 0, normals);
        glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        //    NSData *data = [NSData dataWithBytes:stampTexture length:stampTexture * sizeof(GL_FLOAT) * 2] ;
        //    if (self.vertexBuffers == nil) self.vertexBuffers = [[NSMutableArray alloc] init];
        //    [self.vertexBuffers addObject:data];
        
        
        glPopMatrix();
        
        glDeleteTextures( 1, &stampTexture );
        //set back the brush
        glBindTexture(GL_TEXTURE_2D, brushTexture);
        
        //	glColor4f(lastSetRed,
        //			  lastSetGreen,
        //			  lastSetBlue,
        //			  1.0);
        //
        // Display the buffer
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
        [context presentRenderbuffer:GL_RENDERBUFFER_OES];
    }

else
    {
    static const GLfloat vertices[] = {
		0.0,  410, 0.0,
		410,  410, 0.0,
		0.0, -32, 0.0,
		410, -32, 0.0
        
	};
    
    
	static const GLfloat normals[] = {
		0.0, 0.0, 512,
		0.0, 0.0, 512,
		0.0, 0.0, 512,
		0.0, 0.0, 512
	};
    
	glBindTexture(GL_TEXTURE_2D, stampTexture);
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glNormalPointer(GL_FLOAT, 0, normals);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
//    NSData *data = [NSData dataWithBytes:stampTexture length:stampTexture * sizeof(GL_FLOAT) * 2] ;
//    if (self.vertexBuffers == nil) self.vertexBuffers = [[NSMutableArray alloc] init];
//    [self.vertexBuffers addObject:data];

    
	glPopMatrix();
    
	glDeleteTextures( 1, &stampTexture );
	//set back the brush
	glBindTexture(GL_TEXTURE_2D, brushTexture);
    
    //	glColor4f(lastSetRed,
    //			  lastSetGreen,
    //			  lastSetBlue,
    //			  1.0);
    //
	// Display the buffer
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
    }
}


// Implement this to override the default layer class (which is [CALayer class]).
// We do this so that our view will be backed by a layer that is capable of OpenGL ES rendering.
+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

// The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder {
	
    isStickersMode=NO;
    
    
//	NSMutableArray*	recordedPaths;
	CGImageRef		brushImage;
	CGContextRef	brushContext;
	GLubyte			*brushData;
	size_t			width, height;
    
    if ((self = [super initWithCoder:coder]))
    {
//		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
		
        eaglLayer = (CAEAGLLayer *)self.layer;

		eaglLayer.opaque = NO;
        
		// In this application, we want to retain the EAGLDrawable contents after a call to presentRenderbuffer.
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		
		if (!context || ![EAGLContext setCurrentContext:context]) {
//			[self release];
			return nil;
		}
		
		// Create a texture from an image
		// First create a UIImage object from the data in a image file, and then extract the Core Graphics image
		brushImage = [UIImage imageNamed:@"Particle.png"].CGImage;
		
		// Get the width and height of the image
		width = CGImageGetWidth(brushImage);
		height = CGImageGetHeight(brushImage);
		
		// Texture dimensions must be a power of 2. If you write an application that allows users to supply an image,
		// you'll want to add code that checks the dimensions and takes appropriate action if they are not a power of 2.
		
		// Make sure the image exists
		if(brushImage) {
			// Allocate  memory needed for the bitmap context
			brushData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
			// Use  the bitmatp creation function provided by the Core Graphics framework. 
			brushContext = CGBitmapContextCreate(brushData, width, height, 8, width * 4, CGImageGetColorSpace(brushImage), (CGBitmapInfo)kCGImageAlphaPremultipliedLast);//kCGImageAlphaPremultipliedLast
			// After you create the context, you can draw the  image to the context.
			CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), brushImage);
			// You don't need the context at this point, so you need to release it to avoid memory leaks.
			CGContextRelease(brushContext);
			// Use OpenGL ES to generate a name for the texture.
			glGenTextures(1, &brushTexture);
			// Bind the texture name. 
			glBindTexture(GL_TEXTURE_2D, brushTexture);
			// Set the texture parameters to use a minifying filter and a linear filer (weighted average)
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			// Specify a 2D texture image, providing the a pointer to the image data in memory
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, brushData);
			// Release  the image data; it's no longer needed
            free(brushData);
		}
		
		// Set the view's scale factor
		self.contentScaleFactor = 1.0;
	
		// Setup OpenGL states
		glMatrixMode(GL_PROJECTION);
		CGRect frame = self.bounds;
		CGFloat scale = self.contentScaleFactor;
		// Setup the view port in Pixels
		glOrthof(0, frame.size.width * scale, 0, frame.size.height * scale, -1, 1);
		glViewport(0, 0, frame.size.width * scale, frame.size.height * scale);
		glMatrixMode(GL_MODELVIEW);
		
		glDisable(GL_DITHER);
		glEnable(GL_TEXTURE_2D);
		glEnableClientState(GL_VERTEX_ARRAY);
		
	    glEnable(GL_BLEND);
		// Set a blending function appropriate for premultiplied alpha pixel data
		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
		
		glEnable(GL_POINT_SPRITE_OES);
		glTexEnvf(GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_TRUE);
		glPointSize(width / kBrushScale);
		
		// Make sure to start with a cleared buffer
		needsErase = YES;
		
		// Playback recorded path, which is "Shake Me"
		/*recordedPaths = [NSMutableArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Recording" ofType:@"data"]];
		if([recordedPaths count])
			[self performSelector:@selector(playback:) withObject:recordedPaths afterDelay:0.2];
         */
	}
	
	return self;
}

-(void)setUpBrush_withImagename : (NSMutableString *)imageName
{
    
       isStickersMode=NO;

        CGImageRef		brushImage;
        CGContextRef	brushContext;
        GLubyte			*brushData;
        size_t			width, height;
    
		if (!context || ![EAGLContext setCurrentContext:context]) {
//			[self release];
            //			return 0;
		}
		// Create a texture from an image
		// First create a UIImage object from the data in a image file, and then extract the Core Graphics image
		brushImage = [UIImage imageNamed:imageName].CGImage;
		
		// Get the width and height of the image
		width = CGImageGetWidth(brushImage);
		height = CGImageGetHeight(brushImage);
		
		// Texture dimensions must be a power of 2. If you write an application that allows users to supply an image,
		// you'll want to add code that checks the dimensions and takes appropriate action if they are not a power of 2.
		
    
    // Make sure the image exists
    if(brushImage) {
        // Allocate  memory needed for the bitmap context
        brushData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
        // Use  the bitmatp creation function provided by the Core Graphics framework.
        brushContext = CGBitmapContextCreate(brushData, width, height, 8, width * 4, CGImageGetColorSpace(brushImage), (CGBitmapInfo)kCGImageAlphaPremultipliedLast);//kCGImageAlphaPremultipliedLast
        // After you create the context, you can draw the  image to the context.
        CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), brushImage);
        // You don't need the context at this point, so you need to release it to avoid memory leaks.
        CGContextRelease(brushContext);
        // Use OpenGL ES to generate a name for the texture.
        GLuint _texture;
//        glGenTextures(9, &_brushTexture[texturecount]);
        // Bind the texture name.
        glBindTexture(GL_TEXTURE_2D, _texture);
        
        	glColor4f(lastSetRed,
        			  lastSetGreen,
        			  lastSetBlue,
        			  1.0);
        

        // Set the texture parameters to use a minifying filter and a linear filer (weighted average)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        // Specify a 2D texture image, providing the a pointer to the image data in memory
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, brushData);
        // Release  the image data; it's no longer needed
        free(brushData);
    }
    
    glDisable(GL_DITHER);
    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_VERTEX_ARRAY);
    
    glEnable(GL_BLEND);
    // Set a blending function appropriate for premultiplied alpha pixel data
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    glEnable(GL_POINT_SPRITE_OES);
    glTexEnvf(GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_TRUE);
    glPointSize(width / kBrushScale);
    
}
// If our view is resized, we'll be asked to layout subviews.
// This is the perfect opportunity to also update the framebuffer so that it is
// the same size as our display area.
-(void)layoutSubviews
{
    if (isEditMode)
    {
        [EAGLContext setCurrentContext:context];
        
        [self destroyFramebuffer];
        [self createFramebuffer];
        
//        if (needsErase) {
//            [self erase];
//            needsErase = NO;
//        }
        
        UIImage *myart = [VSCore imageWithImage:[UIImage imageWithContentsOfFile:savedArtWorkimagePath] scaledToSize:CGSizeMake(320, 480)];
        
        UIView* imageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 512, 512)];
        
        UIImageView* subView   = [[UIImageView alloc] initWithImage:myart];
        
        [imageView addSubview:subView];
        //    [subView release];
        subView=NULL;
        UIImage* blendedImage =nil;
        
        UIGraphicsBeginImageContext(imageView.frame.size);
        
        [imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
        
        blendedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        imageView=NULL;
        

        [self mergeWithImage:blendedImage];
    }
    else
    {
        [EAGLContext setCurrentContext:context];
        [self destroyFramebuffer];
        [self createFramebuffer];
        
        // Clear the framebuffer the first time it is allocated
        if (needsErase) {
            [self erase];
            needsErase = NO;
        }
    }
	
}


- (BOOL)createFramebuffer
{
	// Generate IDs for a framebuffer object and a color renderbuffer
	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	// This call associates the storage for the current render buffer with the EAGLDrawable (our CAEAGLLayer)
	// allowing us to draw into a buffer that will later be rendered to screen wherever the layer is (which corresponds with our view).
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
	
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
	// For this sample, we also need a depth buffer, so we'll create and attach one via another renderbuffer.
	glGenRenderbuffersOES(1, &depthRenderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
	glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
	
	if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
	{
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}
	
	return YES;
}

// Clean up any buffers we have allocated.
- (void)destroyFramebuffer
{
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if(depthRenderbuffer)
	{
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}

// Releases resources when they are not longer needed.
- (void) dealloc
{
	if (brushTexture)
	{
		glDeleteTextures(1, &brushTexture);
		brushTexture = 0;
	}
	
	if([EAGLContext currentContext] == context)
	{
		[EAGLContext setCurrentContext:nil];
	}
	
//	[context release];
//	[super dealloc];
}

// Erases the screen
- (void) erase
{
	[EAGLContext setCurrentContext:context];
	
	// Clear the buffer
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glClearColor(0.0, 0.0, 0.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT);
	
	// Display the buffer
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

-(void)undo
{
    [EAGLContext setCurrentContext:context];
	
	// Clear the buffer
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glClearColor(0.0, 0.0, 0.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT);
	
    // Remove last 50 vbos
    for (int i = 0; i < 50; ++i)
    {
        [self.vertexBuffers removeLastObject];
    }
    
    // Render remaining vbos
    for (NSData *vbo in self.vertexBuffers)
    {
        NSUInteger count = vbo.length / (sizeof(GL_FLOAT) * 2);
        glVertexPointer(2, GL_FLOAT, 0, vbo.bytes);
        glDrawArrays(GL_POINTS, 0, count);
    }
    
	// Display the buffer
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
    

}

// Drawings a line onscreen based on where the user touches
- (void) renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end
{
	static GLfloat*		vertexBuffer = NULL;
	static NSUInteger	vertexMax = 64;
	NSUInteger			vertexCount = 0,
    count,
    i;
	
	[EAGLContext setCurrentContext:context];
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	
	// Convert locations from Points to Pixels
	CGFloat scale = self.contentScaleFactor;
	start.x *= scale;
	start.y *= scale;
	end.x *= scale;
	end.y *= scale;
	
	// Allocate vertex array buffer
	if(vertexBuffer == NULL)
		vertexBuffer = malloc(vertexMax * 2 * sizeof(GLfloat));
	
	// Add points to the buffer so there are drawing points every X pixels
	count = MAX(ceilf(sqrtf((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y)) / kBrushPixelStep), 1);
    //NSLog(@"Points Count : %lu" , (unsigned long)count);
    
	for(i = 0; i < count; ++i) {
		if(vertexCount == vertexMax) {
			vertexMax = 2 * vertexMax;
			vertexBuffer = realloc(vertexBuffer, vertexMax * 2 * sizeof(GLfloat));
		}
		
		vertexBuffer[2 * vertexCount + 0] = start.x + (end.x - start.x) * ((GLfloat)i / (GLfloat)count);
		vertexBuffer[2 * vertexCount + 1] = start.y + (end.y - start.y) * ((GLfloat)i / (GLfloat)count);
		vertexCount += 1;
	}
	
	// Render the vertex array
	glVertexPointer(2, GL_FLOAT, 0, vertexBuffer);
	glDrawArrays(GL_POINTS, 0, vertexCount);
	
    // Store VBO for undo
    NSData *data = [NSData dataWithBytes:vertexBuffer length:vertexCount * sizeof(GL_FLOAT) * 2] ;
    if (self.vertexBuffers == nil)
        self.vertexBuffers = [[NSMutableArray alloc] init];
    
    [self.vertexBuffers addObject:data];
    
	// Display the buffer
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

// Reads previously recorded points and draws them onscreen. This is the Shake Me message that appears when the application launches.
- (void) playback:(NSMutableArray*)recordedPaths
{
	NSData*				data = [recordedPaths objectAtIndex:0];
	CGPoint*			point = (CGPoint*)[data bytes];
	NSUInteger			count = [data length] / sizeof(CGPoint),
						i;
	
	// Render the current path
	for(i = 0; i < count - 1; ++i, ++point)
		[self renderLineFromPoint:*point toPoint:*(point + 1)];
	
	// Render the next path after a short delay 
	[recordedPaths removeObjectAtIndex:0];
	if([recordedPaths count])
		[self performSelector:@selector(playback:) withObject:recordedPaths afterDelay:0.01];
}


// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    CGRect				bounds = [self bounds];
    UITouch*	touch = [[event touchesForView:self] anyObject];
	// Convert touch point from UIView referential to OpenGL one (upside-down flip)
	location = [touch locationInView:self];
    
    if (isStickersMode)
    {
        //Do something
        UIView* imageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 512, 512)];
		
        UIImageView* subView   = [[UIImageView alloc] initWithImage:[UIImage imageNamed:stickerName]];
        
        [imageView addSubview:subView];
//        [subView release];
        UIImage* blendedImage =nil;
        
        UIGraphicsBeginImageContext(imageView.frame.size);
        
        [imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
        
        blendedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
//        [imageView release];

        [self addStickersWithImage:blendedImage atPoint:location];
    }
    
    else
    {
        firstTouch = YES;

        location.y = bounds.size.height - location.y;

    }
    
}

// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{  
   	  
	CGRect				bounds = [self bounds];
	UITouch*			touch = [[event touchesForView:self] anyObject];
		  
    if (!isStickersMode)
    {
        // Convert touch point from UIView referential to OpenGL one (upside-down flip)
        if (firstTouch) {
            firstTouch = NO;
            previousLocation = [touch previousLocationInView:self];
            previousLocation.y = bounds.size.height - previousLocation.y;
            
        } else {
            location = [touch locationInView:self];
            location.y = bounds.size.height - location.y;
            previousLocation = [touch previousLocationInView:self];
            previousLocation.y = bounds.size.height - previousLocation.y;
            
        }
		
        // Render the stroke
        [self renderLineFromPoint:previousLocation toPoint:location];
    }
    
    else
    {
        //
    }
}

// Handles the end of a touch event when the touch is a tap.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGRect				bounds = [self bounds];
    UITouch*	touch = [[event touchesForView:self] anyObject];
	   
    if (!isStickersMode)
    {
        if (firstTouch) {
            firstTouch = NO;
            previousLocation = [touch previousLocationInView:self];
            previousLocation.y = bounds.size.height - previousLocation.y;
            [self renderLineFromPoint:previousLocation toPoint:location];
        }
    }
    
    else
    {
        //Do something
    }
    
    if ([ViewDelegate respondsToSelector:@selector(touchesReceivedFor_DrawingView)])
    {
        [ViewDelegate touchesReceivedFor_DrawingView];
    }

}

// Handles the end of a touch event.
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	// If appropriate, add code necessary to save the state of the application.
	// This application is not saving state.
}

- (void)setBrushColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue
{
    isStickersMode=NO;
    
    lastSetRed=red;
	lastSetBlue=blue;
	lastSetGreen=green;
    
//	// Set the brush color using premultiplied alpha values
//	glColor4f(red	* kBrushOpacity,
//			  green * kBrushOpacity,
//			  blue	* kBrushOpacity,
//			  kBrushOpacity);
//    
    
    // Set the brush color using premultiplied alpha values
	glColor4f(lastSetRed,lastSetGreen,lastSetBlue,1);
    

}


- (void) drawErase:(CGPoint)start toPoint:(CGPoint)end
{
    static GLfloat*     eraseBuffer = NULL;
    static NSUInteger   eraseMax = 64;
    
    NSUInteger          vertexCount = 0,
    count,
    i;
    
    [EAGLContext setCurrentContext:context];
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    
    // Convert locations from Points to Pixels
    CGFloat scale = 1.0;//self.contentScaleFactor;
    start.x *= scale;
    start.y *= scale;
    end.x *= scale;
    end.y *= scale;
    
    // Allocate vertex array buffer
    if(eraseBuffer == NULL)
        eraseBuffer = malloc(eraseMax * 2 * sizeof(GLfloat));
    
    // Add points to the buffer so there are drawing points every X pixels
    count = MAX(ceilf(sqrtf((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y)) / kBrushPixelStep), 1);
    
    for(i = 0; i < count; ++i) {
        if(vertexCount == eraseMax) {
            eraseMax = 2 * eraseMax;
            eraseBuffer = realloc(eraseBuffer, eraseMax * 2 * sizeof(GLfloat));
        }
        
        eraseBuffer[2 * vertexCount + 0] = start.x + (end.x - start.x) * ((GLfloat)i / (GLfloat)count);
        eraseBuffer[2 * vertexCount + 1] = start.y + (end.y - start.y) * ((GLfloat)i / (GLfloat)count);
        vertexCount += 1;
    }
    //}
    //glEnable(GL_BLEND);   //   打开混合
    //glDisable(GL_DEPTH_TEST);   //   关闭深度测试
    //glBlendFunc(GL_SRC_ALPHA,   GL_ONE);   //   基于源象素alpha通道值的半透明混合函数
    
    //You need set the mixed-mode
    glBlendFunc(GL_ONE, GL_ZERO);
    //the erase brush color  is transparent.
    glColor4f(0, 0, 0, 0.0);
    
    // Render the vertex array
    glVertexPointer(2, GL_FLOAT, 0, eraseBuffer);
    glDrawArrays(GL_POINTS, 0, vertexCount);
    
    // Display the buffer
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
    
    // at last restore the  mixed-mode
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
}
@end
