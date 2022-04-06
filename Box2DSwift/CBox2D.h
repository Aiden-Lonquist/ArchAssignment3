//
//  Copyright © Borna Noureddin. All rights reserved.
//

#ifndef MyGLGame_CBox2D_h
#define MyGLGame_CBox2D_h

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>


// Set up brick and ball physics parameters here:
//   position, width+height (or radius), velocity,
//   and how long to wait before dropping brick

#define BRICK_POS_X            400
#define BRICK_POS_Y            550
#define BRICK_WIDTH            100.0f
#define BRICK_HEIGHT        10.0f
#define BRICK_WAIT            1.5f

#define Player_POS_X           400
#define Player_POS_Y           100
#define Player_Width           100.0f
#define Player_Height          10.0f

#define BALL_POS_X            400
#define BALL_POS_Y            330
#define BALL_RADIUS            15.0f
#define BALL_VELOCITY        100000.0f
#define BALL_SPHERE_SEGS    128

@interface CBox2D : NSObject 

-(void) HelloWorld; // Basic Hello World! example from Box2D

-(void) LaunchBall;                 // launch the ball
-(void) movePlayer:(float)movement;                 // move the player
-(void) Update:(float)elapsedTime;  // update the Box2D engine
-(void) RegisterHit;                // Register when the ball hits the brick
-(void *)GetObjectPositions;        // Get the positions of the ball and brick

@end

#endif
