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
//  OWDefines.h
//  WormBrowser
 
#ifndef WormBrowser_OWDefines_h
#define WormBrowser_OWDefines_h

#define AppDelegate (OWAppDelegate*)[[UIApplication sharedApplication] delegate]
#define kBarThickness 36.0f
#define kWormGreen [UIColor colorWithRed:0.6f green:0.8f blue:0.2f alpha:1.0]
#define kWormDarker [UIColor colorWithRed:0.5f green:0.7f blue:0.1f alpha:1.0]

#define kOpacityViewWidth 60
#define kOpacityViewHeight 188 + 50 + 29 + 20

#define kUpdateVerticalSlider @"NotificationUpdateVerticalSlider"
#define kUpdateHorizontalSlider @"NotificationUpdateHorizontalSlider"
#define kUpdateLoaderProgress @"NotificationUpdateProgress"
#define kToggleSliderMode @"NotificationSliderModeChange"

#define kNotificationCloseSearchView @"NotificationCloseSearchView"
#define kNotificationShowMetaDataForItem @"NotificationShowMetaForItem"
#define kNotificationSelectSingleObject @"selectSingleObject"
#define kNotificationClearSelection @"NotificationClearSelection"
#define kNotificationCloseMetaView @"NotificationCloseMetaView"
#define kNotificationAllLayersLoaded @"NotificationAllLayersLoaded"
#define kResetAllNotification @"NotificationResetAll"
#define kUpdateCameraSetting @"NotificationUpdateCamera"

#define kMenuFontIpad [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:14]
#define kMenuFontIphone [UIFont fontWithName:@"HelveticaNeue-Bold" size:14]


#define kOpacityViewBackground [UIColor colorWithWhite:0.8f alpha:0.5f]
#define kButtonViewBackground kOpacityViewBackground
#define kSelectedLabelBackgroundColor [UIColor blackColor]
#define kSelectedLabelFontColor [UIColor whiteColor]


// save an image after each 'tap' to select
#define SAVE_IMAGES 0

// blend by drawgroup
// 0 -> blends each draw
// 1 -> blends each drawgropu
#define BLEND_BY_DRAWGROUP 0

#define kTestFlightTeamToken @"3d71b54ba052353b3e21fa1e85f7148d_MTY2MTcwMjAxMi0xMi0xMyAxMzozNzoyMS40MzYzMDk"

//#define kMeshData @"reduced"

typedef enum {
    barButton_home,
    barButton_star,
    barButton_mail,
    barButton_action,
    barButton_search,
    barButton_searchDone,
    barButton_close,
    barButton_scrollToSkin,
    barButton_scrollToOrgans,
    barButton_scrollToMuscles,
    barButton_scrollToNeurons
} barButtons;

typedef enum {
    layerCuticle,
    layerNeurons,
    layerMuscle,
    layerOrgans,
    NUMBER_OF_LAYERS,
} layerType;

typedef enum {
    renderSettingLow,
    renderSettingLow4X,
    renderSettingMedium,
    renderSettingMedium4X,
    renderSettingHigh,
    renderSettingHigh4X,
    renderSettingLast,
} renderSetting;



struct vertexDataTextured
{
	GLKVector3		vertex;
	GLKVector3		normal;
	GLKVector2      texCoord;
};
typedef struct vertexDataTextured vertexDataTextured;
typedef vertexDataTextured* vertexDataTexturedPtr;

enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};


#endif
