//
//    OpenWorm Browser for iOS **
//
//    Developed for the OpenWorm.org project.
//    Inspired / ported from Google Body Browser (now https://code.google.com/p/open-3d-viewer/)
//    Released under MIT license
//
//    Copyright 2012 Rich Stoner
//
//    Permission is hereby granted, free of charge, to any person obtaining
//    a copy of this software and associated documentation files (the
//    "Software"), to deal in the Software without restriction, including
//    without limitation the rights to use, copy, modify, merge, publish,
//    distribute, sublicense, and/or sell copies of the Software, and to
//    permit persons to whom the Software is furnished to do so, subject to
//    the following conditions:
//
//    The above copyright notice and this permission notice shall be
//    included in all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//    WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

//
//  WSEntityInfo.h
//  OpenWormViewer
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

/** OWEntityInfo description
 
 */
@interface OWEntityInfo : NSObject
{
    int layer;
    int entityID;

    GLuint indexOffset;
    GLuint indexCount;

    GLKVector3 bbl;
    GLKVector3 bbh;
    
    NSString* displayName;
    
}

@property int layer;
@property int entityID;
@property GLuint indexOffset;
@property GLuint indexCount;

@property GLKVector3 bbl;
@property GLKVector3 bbh;
@property(nonatomic, strong) NSString* displayName;

-(void) printDebugString;

@end
