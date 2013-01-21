#printblock1


#TODO: redo these in a non-retarded way
pointWithin = (x, xa, xb) -> (x>xa and x<xb)
#pointInRect = (x1, y1, rectx, recty, halfrectwid, halfrectlen)->
 #               x1 > rectx-halfrectwid and x1 < (rectx + halfrectwid) and y1 > recty-halfrectlen and y1 < (recty + halfrectlen)
pointInRect = (x1, y1, rectx, recty, halfrectwid, halfrectlen)->
               rectx-halfrectwid < x1 < (rectx + halfrectwid) and recty-halfrectlen < y1 < (recty + halfrectlen)


#Constant definitions

#Keycodes
KEY_SPACE = 32
KEY_UP_ARROW = 38
KEY_DOWN_ARROW = 40
KEY_LEFT_SHIFT = 16


#Collision type
STATIC = 0
DYNAMIC = 1


#Hitbox types
NON_PHYSICAL = 0
RECTANGLE = 1
CIRCLE = 2


#Maybe I sh
#Collision reaction types

NON_OPERATOR = 0 #Something that collides using standard physics based methods

OPERATOR = 1 #Something that operates on objects in dynamic ways - ie, a bullet or a missile,



class Game
        constructor: (@canvas) ->
                @context = @canvas.getContext("2d")
                #the object that the game is focused on (determines which cell is rendered, etc)
                @viewFocus = 0
                @mousex = 0
                @mousey = 0
                @events = []

                @screenHeight = 1
                @screenWidth = 1
                #The set of all the frames (play fields) contained within the game
                @frames = []

                @graphics = {}
                @loadGraphics()
                @loadIntervalId = null

                @loadingComplete = false


                #3d array containing a grid of game cells, and each cell is a list of objects it contains
                #@cells = [] for cell in [0...@worldHeight] for column in [0...@worldWidth]


        init: () ->



        #Purpose: Core loop, runs the game physics
        run: () ->


                #console.log("game tick")
                frame.run(1, @context, @events, @mousex, @mousey) for frame in @frames when frame.active

                #empties the event que after all the objects have had the chance to see them
                @events = []










        loadGraphics: () ->

                @graphics['resources/warrior1_0-test-01.png'] = new Image()
                @graphics['resources/warrior1_0-test-01.png'].src = 'resources/warrior1_0-test-01.png'


                @graphics['resources/jswars_gfx/asteroid.png'] = new Image()
                @graphics['resources/jswars_gfx/asteroid.png'].src = 'resources/jswars_gfx/asteroid.png'


                @graphics['resources/background_1.png'] = new Image()
                @graphics['resources/background_1.png'].src = 'resources/background_1.png'

                @graphics['resources/gems2-15.png'] = new Image()
                @graphics['resources/gems2-15.png'].src = 'resources/gems2-15.png'


                for i in [0..7]
                        @graphics['resources/shieldAnimation/pwr02test2-'+i+'.png'] = new Image()
                        @graphics['resources/shieldAnimation/pwr02test2-'+i+'.png'].src = 'resources/shieldAnimation/pwr02test2-'+i+'.png'

                #@loadIntervalId = setInterval("window.game.loadProgress()", 200)

        loadProgress: () ->
                @loadingComplete = true
                for src, image of @graphics
                        if not image.complete
                                @loadingComplete = false



#Frame objects are contained within game and have their own coordinate system
# All frames operate on the same core set of principles, but each frame can have
# different scripts that run each cycle and alter the world for the purpose of game mechanics.
class Frame
        constructor: (@width, @height, @graphics) ->
                @player = 0
                @map = []
                @collisionCellSidelength = 10
                @active = false
                @collisionMapWidth =Math.floor(@width/@collisionCellSidelength)
                @collisionMapHeight = Math.floor(@height/@collisionCellSidelength)
                @collisionMap = []
                @idCount = 0

                @background = @graphics['resources/background_1.png']


        # Draws the background and other non-denominational (menus etc)
        # things to the screen
        draw: (context) ->
                context.drawImage(@background, 0, 0, @width, @height)
        #newId: void -> string
        # produces a unique (for a give frame) string to be used as an ID
        newId: () ->
                @idCount++
                return String(@idCount)

        #Runs the core features of the Frame (drawing the map, game mechanics, running frame-specific scripts)
        run: (elapsedTime, context, events, mousex, mousey) ->

                #add another function for custom code
                @collisionMap = ([] for cell in [0...@collisionMapHeight] for column in [0...@collisionMapWidth])
                #console.log(@collisionMap.length)




                for entity in @map
                        entity.updateInput(events, mousex, mousey)
                        entity.run(elapsedTime)
                        @writeToCollisionMap(entity)

                for entity in @map
                        if entity.collisionType is DYNAMIC and entity.alive
                                partner = @doesCollide(entity)
                                if partner isnt false
                                        @collide(entity, partner)

                #TODO: why does this sometimes produce an error?
                #@map.splice(@map.indexOf(entity), 1) for entity in @map when not entity.alive

                #Removes entities in the map that are marked as dead
                splices = 0
                for i in [0...@map.length]
                        if i < @map.length - splices
                                if not @map[i].alive
                                        @map.splice(i, 1)
                                        i-=1
                                        splices++

                @draw(context)
                entity.draw(context) for entity in @map

        #writeToCollisionMap: Entity -> void
        # Writes the general silhouette (called a hitfield) of the entity to the
        # collision map, which is used for broad phase collision detection
        # (ie, narrowing the number of expensive collision detection calls that
        # are necessary)
        writeToCollisionMap: (entity) ->

                #TODO: improve readability with more concise stuff here? Also computing an awful lot of floors


                # Considers a square hitfield around each circular entity,
                # and a rectangular one around each rectangular entity
                if entity.hitboxType is CIRCLE
                        for x in [Math.floor((entity.x-entity.radius)/@collisionCellSidelength)..Math.floor((entity.x+entity.radius)/@collisionCellSidelength)]
                                for y in [Math.floor((entity.y-entity.radius)/@collisionCellSidelength)..Math.floor((entity.y+entity.radius)/@collisionCellSidelength)]
                                        if 0 < x < @collisionMapWidth and 0 < y < @collisionMapHeight
                                                @collisionMap[x][y].push(entity)

                else if entity.hitboxType is RECTANGLE
                        for x in [Math.floor((entity.x-entity.halfWidth)/@collisionCellSidelength)..Math.floor((entity.x+entity.halfWidth)/@collisionCellSidelength)]
                                for y in [Math.floor((entity.y-entity.halfHeight)/@collisionCellSidelength)..Math.floor((entity.y+entity.halfHeight)/@collisionCellSidelength)]
                                        if 0 < x < @collisionMapWidth and 0 < y < @collisionMapHeight
                                                @collisionMap[x][y].push(entity)

        #doesCollide: Entity -> (union False Entity)
        # Does this entity collide? If so, who does it collide with?
        doesCollide: (entity) ->

                # Broad phase collision detection, inspecting the
                # hitfield occupied by the entity, to see if they
                # are overlapping anything else
                potentialPartners = {}
                if entity.hitboxType is CIRCLE
                        for x in [Math.floor((entity.x-entity.radius)/@collisionCellSidelength)..Math.floor((entity.x+entity.radius)/@collisionCellSidelength)]
                                for y in [Math.floor((entity.y-entity.radius)/@collisionCellSidelength)..Math.floor((entity.y+entity.radius)/@collisionCellSidelength)]
                                        if 0 < x < @collisionMapWidth and 0 < y < @collisionMapHeight
                                                for potentialPartner in @collisionMap[x][y]
                                                        potentialPartners[potentialPartner.id] = potentialPartner


                # Checks each potential collision partner with the
                # more expensive, but more accurate narrow-phase
                # collision detector
                return partner for key, partner of potentialPartners when @doesCollideWith(entity, partner)

                #if none of the other partners are a match, return false
                return false

        #doesCollideWith: Entity, Entity -> Boolean
        # Does this entity collide with this partner?
        # Narrow phase collision detection, expensive,
        # but much more accurate than broad phase
        doesCollideWith: (entity, partner) ->
                #TODO: remove the neccessity for this hack, probably part of the broad phase collision detection stuff
                if entity is partner or not partner.alive then return false

                squareDist = (x1, y1, x2, y2) -> Math.pow(x1-x2, 2) + Math.pow(y1-y2, 2)

                if partner.hitboxType is RECTANGLE
                        # Either the distance between the outside line of the rectangle and the centre of the circle is less than the
                        # radius of the circle, or the distance between the centre of the circle and the corners of the rectangle is
                        # less than the radius for there to be a collision
                        partnerPointInRect = (x, y) -> pointInRect(x, y, partner.x, partner.y, partner.halfWidth, partner.halfHeight)
                        a = partnerPointInRect(entity.x+entity.radius, entity.y)
                        b = partnerPointInRect(entity.x-entity.radius, entity.y)
                        c = partnerPointInRect(entity.x, entity.y+entity.radius)
                        d = partnerPointInRect(entity.x, entity.y-entity.radius)
                        sqRadius = Math.pow(entity.radius, 2)
                        e = sqRadius > squareDist(entity.x, entity.y, partner.x+partner.halfWidth, partner.y - partner.halfHeight) or sqRadius > squareDist(entity.x, entity.y, partner.x-partner.halfWidth, partner.y - partner.halfHeight) or  sqRadius > squareDist(entity.x, entity.y, partner.x+partner.halfWidth, partner.y + partner.halfHeight) or sqRadius > squareDist(entity.x, entity.y, partner.x-partner.halfWidth, partner.y + partner.halfHeight)
                        #This is BAAAAAAAAD. Fix it bitch.
                        return a or b or c or d or e

                else if partner.hitboxType is CIRCLE
                        # If the distance between the centres of the two circles is less than
                        # the sum of their radii, then they are overlapping

                        d = squareDist(entity.x, entity.y, partner.x, partner.y) #Calculating the square of the distance
                        r = Math.pow(entity.radius+partner.radius, 2) #Calculating the square sum of the radii

                        return d < r


        #collision: Entity Entity -> void
        # Determines the effects of collision on two collision partners
        collide: (partner1, partner2) ->
                #TODO: more concise ordering and logic
                if partner1.operatorLevel is 0 and partner2.operatorLevel is 0
                        @physicalCollide(partner1, partner2)


                else if partner1.operatorLevel > partner2.operatorLevel
                        partner1.collide(partner2)

                else if partner2.operatorLevel > partner1.operatorLevel
                        partner2.collide(partner1)


                partner1.hasCollided(partner2)
                partner2.hasCollided(partner1)

        #physicalCollide: Entity Entity -> void
        # Collides two physical bodies.
        physicalCollide: (partner1, partner2) ->
                if partner1.hitboxType is NON_PHYSICAL or partner2.hitboxType is NON_PHYSICAL
                        #TODO: WTF?
                        dog = 1

                else if partner1.hitboxType is RECTANGLE or partner2.hitboxType is RECTANGLE

                        #do collision for circle vs rectangle (rectangles can't move, so one partner must be a circle)
                        if partner1.hitboxType is RECTANGLE
                                rect = partner1
                                circle = partner2
                        else
                                rect = partner2
                                circle = partner1

                        xdist = Math.abs(circle.x-(rect.x))
                        ydist = Math.abs(circle.y-(rect.y))




                        if circle.x > rect.x
                                if circle.y > rect.y
                                        #top right quadrant

                                        if xdist < ydist
                                                circle.yVelocity = -circle.yVelocity
                                                circle.y=rect.y+rect.halfHeight+circle.radius
                                        else
                                                circle.xVelocity = -circle.xVelocity
                                                circle.x=rect.x+rect.halfWidth+circle.radius
                                else
                                        #bottom right quadrant

                                        if xdist < ydist
                                                circle.yVelocity = -circle.yVelocity
                                                circle.y=rect.y-rect.halfHeight-circle.radius
                                        else
                                                circle.xVelocity = -circle.xVelocity
                                                circle.x=rect.x+rect.halfWidth+circle.radius
                        else
                                if circle.y > rect.y
                                        #top left quadrant

                                        if xdist < ydist
                                                circle.yVelocity = -circle.yVelocity
                                                circle.y=rect.y+rect.halfHeight+circle.radius
                                        else
                                                circle.xVelocity = -circle.xVelocity
                                                circle.x=rect.x-rect.halfWidth-circle.radius
                                else
                                        #bottom left quadrant

                                        if xdist < ydist
                                                circle.yVelocity = -circle.yVelocity
                                                circle.y=rect.y-rect.halfHeight-circle.radius
                                        else
                                                circle.xVelocity = -circle.xVelocity
                                                circle.x=rect.x-rect.halfWidth-circle.radius


                else if partner1.hitboxType is CIRCLE and partner2.hitboxType is CIRCLE
                        console.log('circle on circle collision')
                        # Much of the math for circle-circle collisions has been adapted from
                        # http://ericleong.me/research/circle-circle
                        # Written by: Eric Leong



                        #First, we must correct the position of the circles
                        # We do this by finding the midpoint between the two
                        # circle centres, and adjusting the circles along this vector
                        # by equal amounts so that they are no longer overlapping
                        '
                        midpointx = (partner1.x + partner2.x)/2
                        midpointy = (partner1.y + partner2.y)/2
                        dist = Math.sqrt(Math.pow(partner1.x-partner2.x, 2) + Math.pow(partner1.y-partner2.y, 2))
                        newx = midpointx + partner1.radius * (partner1.x - partner2.x)/dist
                        newy = midpointy + partner1.radius * (partner1.y - partner2.y)/dist
                        partner2.x = midpointx + partner2.radius * (partner2.x - partner1.x)/dist #Debug here and below as well, are the state changes intentional?
                        partner2.y = midpointy + partner2.radius * (partner2.y - partner1.y)/dist
                        partner1.x = newx
                        partner1.y = newy
                        '


                        #TODO: instead of just going back in velocity, call physics with -1 elapsedtime. That way, if the object was decelerating when it was moving into
                        # collision, it will completely clear the collision (which theoretically will sometimes be an issue with current system)
                        partner1.x -= partner1.xVelocity
                        partner1.y -= partner1.yVelocity

                        partner2.x -= partner2.xVelocity
                        partner2.y -= partner2.yVelocity

                        printCoords = (entity) -> console.log(entity.id+' :('+entity.x+', '+entity.y+')')
                        #The math for determining the collision response for two colliding circles.
                        console.log(partner1.id+'VEL-precollision: ('+partner1.xVelocity+' ,'+partner1.yVelocity+')')
                        printCoords(partner1)
                        console.log(partner2.id+'VEL-precollision: ('+partner2.xVelocity+' ,'+partner2.yVelocity+')')
                        printCoords(partner2)


                        console.log('************************************COLLISION--HAPPENS***********************************')
                        d = partner1.radius + partner2.radius #THIS LINE IS POTENTIAL DEBUG POINT
                        nx = (partner2.x - partner1.x)/d
                        ny = (partner2.y - partner1.y)/d
                        p = 2*(partner1.xVelocity*nx + partner1.yVelocity*ny - partner2.xVelocity*nx - partner2.yVelocity*ny)/(partner1.mass + partner2.mass)
                        partner1.xVelocity = partner1.xVelocity - p*partner2.mass*nx
                        partner1.yVelocity = partner1.yVelocity - p*partner2.mass*ny
                        partner2.xVelocity = partner2.xVelocity + p*partner1.mass*nx
                        partner2.yVelocity = partner2.yVelocity + p*partner1.mass*ny


                        '
                        newVelX1 = (partner1.xVelocity * (partner1.mass - partner2.mass) + (2 * partner2.mass * partner2.xVelocity)) / (partner1.mass + partner2.mass)
                        newVelY1 = (partner1.yVelocity * (partner1.mass - partner2.mass) + (2 * partner2.mass * partner2.yVelocity)) / (partner1.mass + partner2.mass)
                        newVelX2 = (partner2.xVelocity * (partner2.mass - partner1.mass) + (2 * partner1.mass * partner1.xVelocity)) / (partner1.mass + partner2.mass)
                        newVelY2 = (partner2.yVelocity * (partner2.mass - partner1.mass) + (2 * partner1.mass * partner1.yVelocity)) / (partner1.mass + partner2.mass)
                        partner1.xVelocity = newVelX1
                        partner2.yVelocity = newVelY1
                        partner1.xVelocity = newVelX2
                        partner2.yVelocity = newVelY2
                        '

                        '
                        partner1.x += partner1.xVelocity
                        partner1.y += partner1.yVelocity
                        partner2.x += partner2.xVelocity
                        partner2.y += partner2.yVelocity
                        '
                        console.log(partner1.id+'VEL-postcollision: ('+partner1.xVelocity+' ,'+partner1.yVelocity+')')
                        printCoords(partner1)
                        console.log(partner2.id+'VEL-postcollision: ('+partner2.xVelocity+' ,'+partner2.yVelocity+')')
                        printCoords(partner2)

class BasicFrame extends Frame
        constructor: (_width, _height, _graphics) ->
                super(_width, _height, _graphics)
                @wallWidth = @width/40
                @wallHeight = @wallWidth#@height/10

                for x in [0...40]
                        @map.push(new Wall(@map, @newId(), @graphics, x*@wallWidth+0.5*@wallWidth, 0+0.5*@wallHeight, 0.5*@wallWidth, 0.5*@wallHeight))
                        @map.push(new Wall(@map, @newId(), @graphics, x*@wallWidth+0.5*@wallWidth, @height - 0.5*@wallHeight, 0.5*@wallWidth, 0.5*@wallHeight))

                for y in [0...20]
                        @map.push(new Wall(@map, @newId(), @graphics, 0+0.5*@wallWidth, y*@wallHeight+ 0.5*@wallHeight, 0.5*@wallWidth, 0.5*@wallHeight))
                        @map.push(new Wall(@map, @newId(), @graphics, @width-0.5*@wallWidth, y*@wallHeight+ 0.5*@wallHeight, 0.5*@wallWidth, 0.5*@wallHeight))

#entity = new Entity(Number, Number)
#Basic class that describes a physical entity, must at the very least have a position
class Entity
        constructor: (@map, @id, @graphics, @x, @y) ->
                @hitboxType = NON_PHYSICAL
                @collisionType = STATIC
                @operatorLevel = NON_OPERATOR
                @alive = true
                @idCount = 0
                @health = 1
                @imageCentreX = 0
                @imageCentreY = 0




        draw: (context) ->

        collide: (partner) ->

        hasCollided: (partner) ->

        damage: () ->

        updateInput: (events, mousex, mousey) ->

        #Produces a new, unique (within the frame) id
        newId: () ->
                @idCount++
                return @id+":"+String(@idCount)

        run: () ->



class Wall extends Entity
        constructor: (_map, _id, _graphics, _x, _y, @halfWidth, @halfHeight) ->
                super(_map, _id, _graphics, _x, _y)

                @hitboxType = RECTANGLE
                @operatorLevel = NON_OPERATOR
                @image = @graphics['resources/gems2-15.png']

        draw: (context) ->
                context.drawImage(@image, @x-@halfWidth, @y-@halfHeight, 2*@halfWidth, 2*@halfHeight)

        run: (elapsedTime) ->



#a portal = new Portal(Num, Num, Num, (union Portal false), Frame, Num, Num)
class Portal extends Entity
        constructor: (_map, _id, _graphics, _x, _y, @exit, @frame, @halfWidth, @halfHeight) ->
                super(_map, _id, _graphics, _x, _y)
                @hitboxType = RECTANGLE
                @operatorLevel = OPERATOR
                @spawnx = 0
                @spawny = 0

        collide: (partner) ->
                console.log('portal collide!')
                if partner.id is 'player'
                        @exit.receivePlayer(partner)
                        @frame.active = false


        receivePlayer: (player) ->
                player.x = @spawnx
                player.y = @spawny
                @frame.player = player
                @frame.map.push(player)
                @frame.active = true

        draw: (context) ->
                context.fillRect(@x-@halfWidth,@y-@halfHeight,2*@halfWidth,2*@halfHeight)

#mobile = new Mobile(Number, Number, Number, Number)
# A class that serves as the basis for all things that move, and occupy a circular space
class Mobile extends Entity
        constructor: (_map, _id, _graphics, _x, _y, _radius, _mass, _xVelocity, _yVelocity) ->
                super(_map, _id, _graphics, _x, _y)
                #CAREFUL HERE, ABOUT MAP, DO I REALLY WANT THIS?

                @hitboxType = CIRCLE
                @collisionType = DYNAMIC
                @radius = _radius
                @mass = _mass
                @xVelocity = _xVelocity
                @yVelocity = _yVelocity
                @xForce = 0
                @yForce = 0
                @xAcceleration = 0
                @yAcceleration = 0
                @name = "Nil"

                #The last time that physics has been run
                @lastTime = 0



        #physics: Number -> void
        # Simulates physics for the elapsed time period
        physics: (elapsedTime) ->
                @xAcceleration = @xForce/@mass
                @yAcceleration = @yForce/@mass

                #Calculates next position using the third integral of
                #acceleration, assuming constant acceleration over the
                #time interval

                @x += (1/2)*@xAcceleration*elapsedTime*elapsedTime + @xVelocity*elapsedTime
                @y += (1/2)*@yAcceleration*elapsedTime*elapsedTime + @yVelocity*elapsedTime

                #Calculates next velocity using the seconed integral of
                #acceleration, assuming constant acceleration over the
                #time interval

                @xVelocity = @xAcceleration*elapsedTime + @xVelocity
                @yVelocity = @yAcceleration*elapsedTime + @yVelocity




        #collide: Entity -> void
        # Consumes the collision partner, and computes all the collision physics
        collide: (partner) ->
                console.log('handling collide when i shouldnt be')

        #run: Number -> void
        # Called by the update loop on game, performs core state manipulations on the mobile
        run: (elapsedTime) ->
                @physics(elapsedTime)



class Player extends Mobile
        constructor:(_map, _id, _graphics, _x, _y, _radius) ->
                super(_map, _id, _graphics, _x, _y, _radius, _mass= 1, _xVelocity=0, _yVelocity=0)
                @mousex = 0
                @mousey = 0
                @thrustForward = false
                @thrustBackward = false
                @fire = false

                @animation = new PlayerAnimation(this, @graphics, @x, @y)
                @imageCentreX = 27#@radius
                @imageCentreY = 30 #@radius
                @image = @graphics['resources/warrior1_0-test-01.png']

        #updateInput: (listof Events), Num, Num-> void
        # Called once per tick, gives event and mouse coordinate information
        updateInput:(events, _mousex, _mousey) ->
                #Obviously unpacking will be abstracted, this is just for testing
                @mousex = _mousex
                @mousey = _mousey
                @processEvent(event) for event in events

        fireBullet: (fireDirectionX, fireDirectionY) ->
                bulletspeed = 10
                bulletradius = 5

                @map.push(new Bullet(
                        _map = @map,
                        _id = @newId(),
                        _graphics = @graphics,
                        _x = @x + fireDirectionX*(@radius+bulletradius+Math.abs(@xVelocity)),
                        _y =  @y + fireDirectionY*(@radius+bulletradius+Math.abs(@yVelocity)),
                        _radius = bulletradius,
                        _mass = 1,
                        _xVelocity = @xVelocity + fireDirectionX*bulletspeed,
                        _yVelocity = @yVelocity + fireDirectionY*bulletspeed))


        fireMissiles: (destinationX, destinationY) ->
                initialThrust = 2
                missile1radius = 5
                missile2radius = 5

                missile1DirectionX = -@directionY
                missile1DirectionY = @directionX

                missile2DirectionX = @directionY
                missile2DirectionY = -@directionX




                missile1 = new Missile(
                        @map,
                        @newId(),
                        @graphics,
                        _x = @x + missile1DirectionX*(@radius+missile1radius),
                        _y = @y + missile1DirectionY*(@radius+missile1radius),
                        _radius = missile1radius,
                        _mass = 1,
                        _xVelocity = @xVelocity + missile1DirectionX*initialThrust,
                        _yVelocity = @yVelocity + missile1DirectionY*initialThrust,
                        _destinationX = destinationX,
                        _destinationY = destinationY)


                missile2 = new Missile(
                        @map,
                        @newId(),
                        @graphics,
                        _x = @x + missile2DirectionX*(@radius+missile2radius),
                        _y = @y + missile2DirectionY*(@radius+missile2radius),
                        _radius = missile2radius,
                        _mass = 1,
                        _xVelocity = @xVelocity + missile2DirectionX*initialThrust,
                        _yVelocity = @yVelocity + missile2DirectionY*initialThrust,
                        _destinationX = destinationX,
                        _destinationY = destinationY)


                @map.push(missile1, missile2)

        #processEvent: Event -> Void
        # consumes an event object, determines its type
        # and responds accordingly
        processEvent:(event) ->
                if event.type is 'keydown'
                        switch event.keyCode
                                when KEY_SPACE
                                        @fire = true

                                when KEY_UP_ARROW
                                        @thrustForward = true

                                when KEY_DOWN_ARROW
                                        @thrustBackward = true

                                when KEY_LEFT_SHIFT
                                        @doFireMissiles = true

                                #TODO: proper error handling
                                else console.log("Unexpected keycode: "+event.keyCode)

                else if event.type is 'keyup'
                        switch event.keyCode
                                when KEY_UP_ARROW
                                        @thrustForward = false
                                when KEY_DOWN_ARROW
                                        @thrustBackward = false

                                #TODO: proper error handling
                                else console.log("Unexpected keycode")


        damage: (damageTaken) ->
                @animation.animateShield = true



        # Runs the core physics of Player, also runs
        # player-specific scripts for gameplay
        run: (elapsedTime) ->

                #console.log("Run is being called, ("+@x+" ,"+@y+")")
                dist = Math.sqrt(Math.pow(@x-@mousex, 2) + Math.pow(@y-@mousey, 2))
                @directionX = (@mousex - @x)/dist
                @directionY = (@mousey - @y)/dist

                #If i want direction from mouse, but constant magnitude of acceleration
                # Potentially just change to mousex mousey, if i want mouse to be responsible for
                # magnitude of acceleration as well.
                if @thrustForward
                        @xForce += @directionX*0.1
                        @yForce += @directionY*0.1

                else if @thrustBackward
                        @xForce -= @directionX*0.1
                        @yForce -= @directionY*0.1
                if @fire

                        @fireBullet(@directionX, @directionY)
                        @fire = false

                if @doFireMissiles
                        @fireMissiles(@mousex, @mousey)
                        @doFireMissiles = false
                #@xVelocity = 0.01*mouseDirectionX*dist
                #@yVelocity = 0.01*mouseDirectionY*dist
                @physics(elapsedTime)
                @xForce = 0
                @yForce = 0


        draw: (context) ->
                dotProd = (x1, y1, x2, y2) -> x1*x2 + y1*y2

                #Degree against the x axis, and works only for normalized vectors
                vectorToRadians = (x, y) ->
                        theta = Math.acos(dotProd(x, y, 1, 0))
                        if y<0 then return 2*3.14 - theta else return theta





                context.save()

                context.translate(@x, @y)
                context.rotate(vectorToRadians(@directionX, @directionY))
                context.drawImage(@image, -@imageCentreX, -@imageCentreY)
                context.translate(@x, @y)
                context.restore();

                @animation.draw(context)

        hasCollided: (partner) ->
                console.log(partner.id)
                #TODO: generalize this
                if partner.id is 'asteroid'
                        @damage(0.5)



class Bullet extends Mobile
        constructor:(_map, _id, _graphics, _x, _y, _radius, _mass, _xVelocity, _yVelocity) ->
                super(_map, _id, _graphics, _x, _y, _radius, _mass, _xVelocity, _yVelocity)
                @xVelocity = _xVelocity
                @yVelocity = _yVelocity
                @operatorLevel = OPERATOR
                @hitboxType = CIRCLE
                @collisionType = DYNAMIC
                @damage = 5


        #collide: Entity -> void
        collide: (partner) ->
                if partner.id isnt 'player'
                        partner.damage(@damage)
                        @alive = false

        draw: (context) ->
                context.beginPath()
                context.arc(@x, @y, @radius, 0, 2*Math.PI, true)
                context.fill()

        run: (elapsedTime) ->
                @physics(elapsedTime)



class Asteroid extends Mobile
        constructor:(_map, _id, _graphics, _x, _y, _radius, _mass, _xVelocity, _yVelocity)->
                super(_map, _id, _graphics, _x, _y, _radius, _mass, _xVelocity, _yVelocity)
                @operatorLevel = NON_OPERATOR
                @hitboxType = CIRCLE
                @collisionType = DYNAMIC
                @image = @graphics['resources/jswars_gfx/asteroid.png']
                @imageCentreX = 1.5*@radius
                @imageCentreY = 1.5*@radius
                @health = 15

        draw: (context) ->
                context.drawImage(@image, @x-@imageCentreX, @y-@imageCentreY, 2*@imageCentreX, 2*@imageCentreY)



        run: (elapsedTime) ->
                #When the asteroid dies, it splits into asteroid-children
                # TODO: randomize the size, number and speeds of the children
                if @health < 1
                        @alive = false
                        child1 = new Asteroid(@map, @newId(), @graphics, @x + @radius/2, @y + @radius/2, @radius/2, @mass/4, @xVelocity/4 + 1, @yVelocity/4 + 1)


                        child2 = new Asteroid(@map, @newId(), @graphics, @x + @radius/2, @y - @radius/2, @radius/2, @mass/4, @xVelocity/4 + 1, @yVelocity/4 - 1)

                        child3 = new Asteroid(@map, @newId(), @graphics, @x - @radius/2, @y + @radius/2, @radius/2, @mass/4, @xVelocity/4 - 1, @yVelocity/4 + 1)

                        child4 = new Asteroid(@map, @newId(), @graphics, @x - @radius/2, @y - @radius/2, @radius/2, @mass/4, @xVelocity/4 - 1, @yVelocity/4 - 1)

                        @map.push(child1, child2, child3, child4)

                else
                        @physics(elapsedTime)

        damage: (damageTaken) ->
                @health -= damageTaken

#NOTES
#15 stars
#1920 vertical res
# 128 horizontal
# crop 128*128


#The class containing all the logic for the complex player animations
# TODO: abstract the animation systems
class PlayerAnimation
        constructor: (@player, @graphics, @x, @y) ->


                @animateShield = true
                @shieldImageIterator = 0
                @shieldImageIndex = 0
                @shieldImageIndexMax = 7
                @rotation = 0
                @active = true


        draw: (context) ->
                #14yoffset 68 centre
                if @animateShield
                        console.log('Sheild is animated!')
                        context.globalAlpha = 0.5
                        context.drawImage(@graphics['resources/shieldAnimation/pwr02test2-'+@shieldImageIndex+'.png'],
                                @player.x - @player.radius*1.26, @player.y - @player.radius*1.26, imgWidth = 1.26*@player.radius*2, imgHeight = 1.26*@player.radius*2)
                        context.globalAlpha = 1
                        if @shieldImageIndexMax is @shieldImageIndex
                                @shieldImageIndex = 0
                                @animateShield = false

                        else if @shieldImageIterator is 2
                                @shieldImageIndex++
                                @shieldImageIterator = 0

                        else
                                @shieldImageIterator++




#Missile behaviour: Moves towards a Destination point by applying
# force (thrust) in that direction. Explodes on collision, or when
# it passes a certain threshold distance to it's destination
# TODO: Change missile expiry (distance to destination is unreliable)
class Missile extends Mobile
        constructor:(_map, _id, _graphics, _x, _y, _radius, _mass, _xVelocity, _yVelocity, _destinationX, _destinationY) ->
                super(_map, _id, _graphics, _x, _y, _radius, _mass, _xVelocity, _yVelocity)
                @xVelocity = _xVelocity
                @yVelocity = _yVelocity
                @operatorLevel = OPERATOR
                @hitboxType = CIRCLE
                @collisionType = DYNAMIC
                @damage = 5

                @destinationX = _destinationX
                @destinationY = _destinationY

                @thrust = 200

        collide: (partner) ->
                if partner.id isnt 'player'
                        partner.damage(@damage)
                        @alive = false

        draw: (context) ->
                context.beginPath()
                context.arc(@x, @y, @radius, 0, 2*Math.PI, true)
                context.fill()


        run: (elapsedTime) ->
                dist = Math.sqrt(Math.pow(@destinationX-@x, 2) + Math.pow(@destinationY-@.y, 2))
                if dist < 20
                        @alive = false

                @directionX = (@destinationX - @x)/dist
                @directionY = (@destinationY - @y)/dist
                @xForce = @directionX*Math.max(@thrust*(1/(dist*10)), 2)
                @yForce = @directionY*Math.max(@thrust*(1/(dist*10)), 2)

                @physics(elapsedTime)




class testWall extends Entity
        constructor: (_map, _id, _graphics, _x, _y, @halfWidth, @halfHeight) ->
                super(_map, _id, _graphics, _x, _y)

                @hitboxType = RECTANGLE
        draw: (context) ->
                context.fillRect(@x-@halfWidth,@y-@halfHeight,2*@halfWidth,2*@halfHeight)
        run: (elapsedTime) ->
#Manually fill entity list
#Manually set map in mobiles as entitylist in game



start = (canvas) ->
        #console.info "I started!"
        #setInterval(function(){(new Game canvas 100 100).run()}, 50)
        window.game = new Game(canvas)

        window.game.frames.push(new BasicFrame(1000, 500, window.game.graphics))
        #window.game.frames.push(new Frame(1000, 1000, 'graphics'))
        window.game.frames[0].active = true
        window.game.frames[0].map.push(new Asteroid(window.game.frames[0].map, 'asteroid', window.game.graphics, 300, 300, 30, 1, 0, 0))
        #window.game.frames[0].map.push(new testSphere(window.game.frames[0].map, 'circle2', 'graphics',600, 200, 20))

        #window.game.frames[0].map[1].id = 'Circle2'
        #window.game.frames[0].map[1].xVelocity = 1
        #window.game.frames[0].map[1].yVelocity = 1
        #window.game.frames[0].map[0].xVelocity = -1
        #window.game.frames[0].map[0].yVelocity = -1

        #window.game.frames[1].map.push(new Portal(window.game.frames[0].map, 'portal2', 'graphics', 1000, 300, false, window.game.frames[1], 40, 40))
        #window.game.frames[0].map.push(new Portal(window.game.frames[0].map, 'portal1', 'graphics', 1000, 100, window.game.frames[1].map[0], window.game.frames[0], 40, 40))


        window.game.frames[0].map.push(new Player(window.game.frames[0].map, 'player', window.game.graphics, 200, 200, 40))
        #window.game.frames[0].map.push(new Wall(window.game.frames[0].map, 'wall', window.game.graphics, 300, 250, 50, 50))

        setInterval("window.game.run()", 20)






#So that the canvas context can be passed to the program - figure out a better way
window.startGame = (canvas) -> start(canvas);
