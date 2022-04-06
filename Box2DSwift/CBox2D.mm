//
//  Copyright © Borna Noureddin. All rights reserved.
//

#include <Box2D/Box2D.h>
#include "CBox2D.h"
#include <stdio.h>
#include <map>

// Some Box2D engine paremeters
const float MAX_TIMESTEP = 1.0f/60.0f;
const int NUM_VEL_ITERATIONS = 50;
const int NUM_POS_ITERATIONS = 10;
int cur_velocity_y = BALL_VELOCITY;
int cur_velocity_x = 0;


#pragma mark - Box2D contact listener class

// This C++ class is used to handle collisions
class CContactListener : public b2ContactListener
{
public:
    void BeginContact(b2Contact* contact) {};
    void EndContact(b2Contact* contact) {};
    void PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
    {
        b2WorldManifold worldManifold;
        contact->GetWorldManifold(&worldManifold);
        b2PointState state1[2], state2[2];
        b2GetPointStates(state1, state2, oldManifold, contact->GetManifold());
        if (state2[0] == b2_addState)
        {
            // Use contact->GetFixtureA()->GetBody() to get the body
            b2Body* bodyA = contact->GetFixtureA()->GetBody();
            CBox2D *parentObj = (__bridge CBox2D *)(bodyA->GetUserData());
            // Call RegisterHit (assume CBox2D object is in user data)
            [parentObj RegisterHit];    // assumes RegisterHit is a callback function to register collision
        }
    }
    void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) {};
};


#pragma mark - CBox2D

@interface CBox2D ()
{
    // Box2D-specific objects
    b2Vec2 *gravity;
    b2World *world;
    b2BodyDef *groundBodyDef;
    b2Body *groundBody;
    b2PolygonShape *groundBox;
    b2Body *theBrick, *theBall, *thePlayer;
    CContactListener *contactListener;
    float totalElapsedTime;

    // You will also need some extra variables here for the logic
    bool ballHitBrick;
    bool ballLaunched;
    bool ballHitWall;
}
@end

@implementation CBox2D

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Initialize Box2D
        gravity = new b2Vec2(0.0f, 0.0f);
        world = new b2World(*gravity);
        
        // For HelloWorld
        groundBodyDef = NULL;
        groundBody = NULL;
        groundBox = NULL;

        // For brick & ball sample
        contactListener = new CContactListener();
        world->SetContactListener(contactListener);
        
        // Set up the brick and ball objects for Box2D
        b2BodyDef brickBodyDef;
        brickBodyDef.type = b2_dynamicBody;
        brickBodyDef.position.Set(BRICK_POS_X, BRICK_POS_Y);
        theBrick = world->CreateBody(&brickBodyDef);
        if (theBrick)
        {
            theBrick->SetUserData((__bridge void *)self);
            theBrick->SetAwake(false);
            b2PolygonShape dynamicBox;
            dynamicBox.SetAsBox(BRICK_WIDTH/2, BRICK_HEIGHT/2);
            b2FixtureDef fixtureDef;
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 1.0f;
            fixtureDef.restitution = 1.0f;
            theBrick->CreateFixture(&fixtureDef);
            
            b2BodyDef ballBodyDef;
            ballBodyDef.type = b2_dynamicBody;
            ballBodyDef.position.Set(BALL_POS_X, BALL_POS_Y);
            theBall = world->CreateBody(&ballBodyDef);
            if (theBall)
            {
                theBall->SetUserData((__bridge void *)self);
                theBall->SetAwake(false);
                b2CircleShape circle;
                circle.m_p.Set(0, 0);
                circle.m_radius = BALL_RADIUS;
                b2FixtureDef circleFixtureDef;
                circleFixtureDef.shape = &circle;
                circleFixtureDef.density = 1.0f;
                circleFixtureDef.friction = 0.0f;
                circleFixtureDef.restitution = 1.0f;
                theBall->CreateFixture(&circleFixtureDef);
                
                b2BodyDef playerBodyDef;
                playerBodyDef.type = b2_dynamicBody;
                playerBodyDef.position.Set(Player_POS_X, Player_POS_Y);
                thePlayer = world->CreateBody(&playerBodyDef);
                if (thePlayer)
                {
                    thePlayer->SetUserData((__bridge void *)self);
                    thePlayer->SetAwake(false);
                    b2PolygonShape dynamicBox;
                    dynamicBox.SetAsBox(Player_Width/2, Player_Height/2);
                    b2FixtureDef fixtureDef;
                    fixtureDef.shape = &dynamicBox;
                    fixtureDef.density = 1.0f;
                    fixtureDef.friction = 1.0f;
                    fixtureDef.restitution = 1.0f;
                    thePlayer->CreateFixture(&fixtureDef);                }
            }
        }
        
        totalElapsedTime = 0;
        ballHitBrick = false;
        ballLaunched = false;
        ballHitWall = false;
    }
    return self;
}

- (void)dealloc
{
    if (gravity) delete gravity;
    if (world) delete world;
    if (groundBodyDef) delete groundBodyDef;
    if (groundBox) delete groundBox;
    if (contactListener) delete contactListener;
}

-(void)Update:(float)elapsedTime
{
    // Check here if we need to launch the ball
    //  and if so, use ApplyLinearImpulse() and SetActive(true)
    if (ballLaunched)
    {
        theBall->ApplyLinearImpulse(b2Vec2(0, BALL_VELOCITY), theBall->GetPosition(), true);
        theBall->SetActive(true);
#ifdef LOG_TO_CONSOLE
        NSLog(@"Applying impulse %f to ball\n", BALL_VELOCITY);
#endif
        ballLaunched = false;
    }
    
    // Check if it is time yet to drop the brick, and if so
    //  call SetAwake()
    totalElapsedTime += elapsedTime;
//    if ((totalElapsedTime > BRICK_WAIT) && theBrick)
//        theBrick->SetAwake(true);
    
    // If the last collision test was positive,
    //  stop the ball and destroy the brick
    if (ballHitBrick)
    {
        cur_velocity_y = cur_velocity_y * -1;
        cur_velocity_x = ((rand() % 10) - 0.5) * 20000;
        theBall->SetLinearVelocity(b2Vec2(cur_velocity_x, cur_velocity_y));
        theBall->SetAngularVelocity(0);
        theBrick->SetLinearVelocity(b2Vec2(cur_velocity_x, 0));
        thePlayer->SetLinearVelocity(b2Vec2(0, 0));
        //theBall->SetActive(false);
        //world->DestroyBody(theBrick);
        //theBrick = NULL;
        ballHitBrick = false;
    }
    
    //ball hits right wall
    if (theBall->GetPosition().x > 780)
    {
        cur_velocity_x = abs(cur_velocity_x) * -1;
        theBall->SetLinearVelocity(b2Vec2(cur_velocity_x, cur_velocity_y));
        theBrick->SetLinearVelocity(b2Vec2(cur_velocity_x, 0));
    }
    
    //ball hits left wall
    if (theBall->GetPosition().x < 20)
    {
        cur_velocity_x = abs(cur_velocity_x);
        theBall->SetLinearVelocity(b2Vec2(cur_velocity_x, cur_velocity_y));
        theBrick->SetLinearVelocity(b2Vec2(cur_velocity_x, 0));
    }
    
    //AI scores
    if (theBall->GetPosition().y < 0)
    {
        //reset ball POS
        theBall->SetLinearVelocity(b2Vec2(0, cur_velocity_y*-1));
        theBall->SetTransform(b2Vec2(BALL_POS_X, BALL_POS_Y), 0.0f);
        
        //reset brick POS
        theBrick->SetLinearVelocity(b2Vec2(0, 0));
        theBrick->SetTransform(b2Vec2(BRICK_POS_X, BRICK_POS_Y), 0.0f);
        
        //reset player POS
        thePlayer->SetLinearVelocity(b2Vec2(0, 0));
        thePlayer->SetTransform(b2Vec2(Player_POS_X, Player_POS_Y), 0.0f);
        
    }
    
    //player scores
    if (theBall->GetPosition().y > 600)
    {
        //reset ball POS
        theBall->SetLinearVelocity(b2Vec2(0, cur_velocity_y*-1));
        theBall->SetTransform(b2Vec2(BALL_POS_X, BALL_POS_Y), 0.0f);
        
        //reset brick POS
        theBrick->SetLinearVelocity(b2Vec2(0, 0));
        theBrick->SetTransform(b2Vec2(BRICK_POS_X, BRICK_POS_Y), 0.0f);
        
        //reset player POS
        thePlayer->SetLinearVelocity(b2Vec2(0, 0));
        thePlayer->SetTransform(b2Vec2(Player_POS_X, Player_POS_Y), 0.0f);
        
    }
    
    

    if (world)
    {
        while (elapsedTime >= MAX_TIMESTEP)
        {
            world->Step(MAX_TIMESTEP, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
            elapsedTime -= MAX_TIMESTEP;
        }
        
        if (elapsedTime > 0.0f)
        {
            world->Step(elapsedTime, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
        }
    }
}

-(void)RegisterHit
{
    // Set some flag here for processing later...
    ballHitBrick = true;
}

-(void)LaunchBall
{
    // Set some flag here for processing later...
    ballLaunched = true;
}

-(void)movePlayer:(float)movement
{
    int cur_pos = thePlayer->GetPosition().x;
    thePlayer->SetTransform(b2Vec2(cur_pos + movement/3, Player_POS_Y), 0.0f);
}

-(void *)GetObjectPositions
{
    auto *objPosList = new std::map<const char *,b2Vec2>;
    if (theBall)
        (*objPosList)["ball"] = theBall->GetPosition();
    if (theBrick)
        (*objPosList)["brick"] = theBrick->GetPosition();
    if (thePlayer)
        (*objPosList)["player"] = thePlayer->GetPosition();
    return reinterpret_cast<void *>(objPosList);
}



-(void)HelloWorld
{
    groundBodyDef = new b2BodyDef;
    groundBodyDef->position.Set(0.0f, -10.0f);
    groundBody = world->CreateBody(groundBodyDef);
    groundBox = new b2PolygonShape;
    groundBox->SetAsBox(50.0f, 10.0f);
    
    groundBody->CreateFixture(groundBox, 0.0f);
    
    // Define the dynamic body. We set its position and call the body factory.
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position.Set(0.0f, 4.0f);
    b2Body* body = world->CreateBody(&bodyDef);
    
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBox;
    dynamicBox.SetAsBox(1.0f, 1.0f);
    
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &dynamicBox;
    
    // Set the box density to be non-zero, so it will be dynamic.
    fixtureDef.density = 1.0f;
    
    // Override the default friction.
    fixtureDef.friction = 0.3f;
    
    // Add the shape to the body.
    body->CreateFixture(&fixtureDef);
    
    // Prepare for simulation. Typically we use a time step of 1/60 of a
    // second (60Hz) and 10 iterations. This provides a high quality simulation
    // in most game scenarios.
    float32 timeStep = 1.0f / 60.0f;
    int32 velocityIterations = 6;
    int32 positionIterations = 2;
    
    // This is our little game loop.
    for (int32 i = 0; i < 60; ++i)
    {
        // Instruct the world to perform a single step of simulation.
        // It is generally best to keep the time step and iterations fixed.
        world->Step(timeStep, velocityIterations, positionIterations);
        
        // Now print the position and angle of the body.
        b2Vec2 position = body->GetPosition();
        float32 angle = body->GetAngle();
        
        printf("%4.2f %4.2f %4.2f\n", position.x, position.y, angle);
    }
}

@end
