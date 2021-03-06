breed [consumers consumer]
breed [retailers retailer]
breed [houses house]
breed [distributors distributor]

retailers-own [
  my-store
]

to draw
  reset-ticks
  if mouse-down? [
    let x round mouse-xcor
    let y round mouse-ycor

    if [pcolor] of patch x y = black [
      if (draw-what? = "road") [
        ask patch x y [ set pcolor white ]
      ]

      if (draw-what? = "retail store") [
        ask patch x y [ ask turtles-here [die] ]
        create-retailers 1 [
          set xcor x
          set ycor y
          set shape "circle"

          set color orange
          set size 1.5
          set my-store False
        ]
      ]

      if (draw-what? = "MY STORE") [
        ask patch x y [
          ask turtles-here [die]
        ]
        ask retailers with [ my-store = True] [ die ]
        create-retailers 1 [
          set xcor x
          set ycor y
          set shape "star"
          set color orange
          set size 2.5
          set my-store True
        ]
      ]

      if (draw-what? = "distributor") [
        ask patch x y [
          ask turtles-here [die]
        ]
        create-distributors 1 [
          set xcor x
          set ycor y
          set shape "square"
          set color red
          set size 1.5
        ]
      ]

      if (draw-what? = "house") [
        ask patch x y [
          ask turtles-here [die]
        ]
        create-houses 1 [
          set xcor x
          set ycor y
          set shape "house"
          set color yellow
          set size 1.3
        ]
      ]
    ]

    if (draw-what? = "eraser") [
      ask patch x y [
        set pcolor black
        ask turtles-here [die]
      ]
    ]
  ]
  tick
end

to export-layout
  let filename ""
  while[ filename = "" ]
  [
    set filename user-input "Input Layout Name:"
    if filename = "" [ user-message "The filename shouldn't be empty." ]
  ]
  set filename (word filename ".csv")
  export-world filename
end

to import-layout
  let filename ""
  while[ filename = "" ]
  [
    set filename user-input "Write Layout Name"
    if filename = "" [ user-message "The filename shouldn't be empty." ]
  ]
  set filename (word filename ".csv")
  clear-all
  import-world filename
end








@#$#@#$#@
GRAPHICS-WINDOW
280
10
769
500
-1
-1
13.0
1
15
1
1
1
0
0
0
1
-18
18
-18
18
1
1
1
ticks
30.0

CHOOSER
65
105
203
150
draw-what?
draw-what?
"eraser" "road" "retail store" "house" "distributor" "MY STORE"
2

BUTTON
65
55
128
88
NIL
draw
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
140
55
202
88
clear
clear-all
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
80
15
230
33
City Layout Tools
14
0.0
1

BUTTON
20
165
127
198
NIL
export-layout
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
140
165
242
198
NIL
import-layout
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
20
275
77
320
houses
count houses
17
1
11

MONITOR
95
275
152
320
retailers
count retailers
17
1
11

MONITOR
165
275
237
320
distributors
count distributors
17
1
11

@#$#@#$#@
## ACKNOWLEDGMENT

This model is from Chapter Five of the book "Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo", by Uri Wilensky & William Rand.

* Wilensky, U. & Rand, W. (2015). Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo. Cambridge, MA. MIT Press.

This model is in the IABM Textbook folder of the NetLogo Models Library. The model, as well as any updates to the model, can also be found on the textbook website: http://www.intro-to-abm.com/.

## ERRATA

The code for this model differs somewhat from the code in the textbook. The textbook code calls the STAY procedure, which is not defined here. One of our suggestions in the "Extending the model" section below does, however, invite you to write a STAY procedure.

## WHAT IS IT?

The Traffic Grid Goal model simulates traffic moving in a city grid. It allows you to control traffic lights and global variables, such as the speed limit and the number of cars, and explore traffic dynamics.

This model extends the Traffic Grid model by giving the cars goals, namely to drive to and from work. It is the third in a series of traffic models that use different kinds of agent cognition. The agents in this model use goal-based cognition.

## HOW IT WORKS

Each time step, the cars face the next destination they are trying to get to (either work or home) and attempt to move forward at their current speed. If their current speed is less than the speed limit and there is no car directly in front of them, they accelerate. If there is a slower car in front of them, they match the speed of the slower car and decelerate. If there is a red light or a stopped car in front of them, they stop.

Each car has a house patch and a work patch. (The house patch turns yellow and the work patch turns orange for a car that you are watching.) The cars will alternately drive from their home to work and then from their work to home.

There are two different ways the lights can change. First, the user can change any light at any time by making the light current, and then clicking CHANGE LIGHT. Second, lights can change automatically, once per cycle. Initially, all lights will automatically change at the beginning of each cycle.

## HOW TO USE IT

Change the traffic grid (using the sliders GRID-SIZE-X and GRID-SIZE-Y) to make the desired number of lights. Change any other setting that you would like to change. Press the SETUP button.

At this time, you may configure the lights however you like, with any combination of auto/manual and any phase. Changes to the state of the current light are made using the CURRENT-AUTO?, CURRENT-PHASE and CHANGE LIGHT controls. You may select the current intersection using the SELECT INTERSECTION control. See below for details.

Start the simulation by pressing the GO button. You may continue to make changes to the lights while the simulation is running.

### Buttons

SETUP -- generates a new traffic grid based on the current GRID-SIZE-X and GRID-SIZE-Y and NUM-CARS number of cars. Each car chooses a home and work location. All lights are set to auto, and all phases are set to 0%.

GO -- runs the simulation indefinitely. Cars travel from their homes to their work and back.

CHANGE LIGHT -- changes the direction traffic may flow through the current light. A light can be changed manually even if it is operating in auto mode.

SELECT INTERSECTION -- allows you to select a new "current" intersection. When this button is depressed, click in the intersection which you would like to make current. When you've selected an intersection, the "current" label will move to the new intersection and this button will automatically pop up.

WATCH A CAR -- selects a car to watch. Sets the car's label to its goal. Displays the car's house in yellow and the car's work in orange. Opens inspectors for the watched car and its house and work.

STOP WATCHING -- stops watching the watched car and resets its labels and house and work colors.

### Sliders

SPEED-LIMIT -- sets the maximum speed for the cars.

NUM-CARS -- sets the number of cars in the simulation (you must press the SETUP button to see the change).

TICKS-PER-CYCLE -- sets the number of ticks that will elapse for each cycle. This has no effect on manual lights. This allows you to increase or decrease the granularity with which lights can automatically change.

GRID-SIZE-X -- sets the number of vertical roads there are (you must press the SETUP button to see the change).

GRID-SIZE-Y -- sets the number of horizontal roads there are (you must press the SETUP button to see the change).

CURRENT-PHASE -- controls when the current light changes, if it is in auto mode. The slider value represents the percentage of the way through each cycle at which the light should change. So, if the TICKS-PER-CYCLE is 20 and CURRENT-PHASE is 75%, the current light will switch at tick 15 of each cycle.

### Switches

POWER? -- toggles the presence of traffic lights.

CURRENT-AUTO? -- toggles the current light between automatic mode, where it changes once per cycle (according to CURRENT-PHASE), and manual, in which you directly control it with CHANGE LIGHT.

### Plots

STOPPED CARS -- displays the number of stopped cars over time.

AVERAGE SPEED OF CARS -- displays the average speed of cars over time.

AVERAGE WAIT TIME OF CARS -- displays the average time cars are stopped over time.

## THINGS TO NOTICE

How is this model different than the Traffic Grid model? The one thing you may see at first glance is that cars move in all directions instead of only left to right and top to bottom. You will probably agree that this looks much more realistic.

Another thing to notice is that, sometimes, cars get stuck: as explained in the book this is because the cars are mesuring the distance to their goals "as the bird flies", but reaching the goal sometimes require temporarily moving further from it (to get around a corner, for instance). A good way to witness that is to try the WATCH A CAR button until you find a car that is stuck. This situation could be prevented if the agents were more cognitively sophisticated. Do you think that it could also be avoided if the streets were layed out in a pattern different from the current one?

## THINGS TO TRY

You can change the "granularity" of the grid by using the GRID-SIZE-X and GRID-SIZE-Y sliders. Do cars get stuck more often with bigger values for GRID-SIZE-X and GRID-SIZE-Y, resulting in more streets, or smaller values, resulting in less streets? What if you use a big value for X and a small value for Y?

In the original Traffic Grid model from the model library, removing the traffic lights (by setting the POWER? switch to Off) quickly resulted in gridlock. Try it in this version of the model. Do you see a gridlock happening? Why do you think that is? Do you think it is more realistic than in the original model?

## EXTENDING THE MODEL

Can you improve the efficiency of the cars in their commute? In particular, can you think of a way to avoid cars getting "stuck" like we noticed above? Perhaps a simple rule like "don't go back to the patch you were previously on" would help. This should be simple to implement by giving the cars a (very) short term memory: something like a `previous-patch` variable that would be checked at the time of choosing the next patch to move to. Does it help in all situations? How would you deal with situations where the cars still get stuck?

Can you enable the cars to stay at home and work for some time before leaving? This would involve writing a STAY procedure that would be called instead moving the car around if the right condition is met (i.e., if the car has reached its current goal).

At the moment, only two of the four arms of each intersection have traffic lights on them. Having only two lights made sense in the original Traffic Grid model because the streets in that model were one-way streets, with traffic always flowing in the same direction. In our more complex model, cars can go in all directions, so it would be better if all four arms of the intersection had lights. What happens if you make that modification? Is the flow of traffic better or worse?

## RELATED MODELS

- "Traffic Basic": a simple model of the movement of cars on a highway.

- "Traffic Basic Utility": a version of "Traffic Basic" including a utility function for the cars.

- "Traffic Basic Adaptive": a version of "Traffic Basic" where cars adapt their acceleration to try and maintain a smooth flow of traffic.

- "Traffic Basic Adaptive Individuals": a version of "Traffic Basic Adaptive" where each car adapts individually, instead of all cars adapting in unison.

- "Traffic 2 Lanes": a more sophisticated two-lane version of the "Traffic Basic" model.

- "Traffic Intersection": a model of cars traveling through a single intersection.

- "Traffic Grid": a model of traffic moving in a city grid, with stoplights at the intersections.

- "Gridlock HubNet": a version of "Traffic Grid" where students control traffic lights in real-time.

- "Gridlock Alternate HubNet": a version of "Gridlock HubNet" where students can enter NetLogo code to plot custom metrics.

The traffic models from chapter 5 of the IABM textbook demonstrate different types of cognitive agents: "Traffic Basic Utility" demonstrates _utility-based agents_, "Traffic Grid Goal" demonstrates _goal-based agents_, and "Traffic Basic Adaptive" and "Traffic Basic Adaptive Individuals" demonstrate _adaptive agents_.

## HOW TO CITE

This model is part of the textbook, “Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo.”

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Rand, W., Wilensky, U. (2008).  NetLogo Traffic Grid Goal model.  http://ccl.northwestern.edu/netlogo/models/TrafficGridGoal.  Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the textbook as:

* Wilensky, U. & Rand, W. (2015). Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo. Cambridge, MA. MIT Press.

## COPYRIGHT AND LICENSE

Copyright 2008 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2008 Cite: Rand, W., Wilensky, U. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
true
0
Polygon -7500403 true true 180 15 164 21 144 39 135 60 132 74 106 87 84 97 63 115 50 141 50 165 60 225 150 285 165 285 225 285 225 15 180 15
Circle -16777216 true false 180 30 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 80 138 78 168 135 166 135 91 105 106 96 111 89 120
Circle -7500403 true true 195 195 58
Circle -7500403 true true 195 47 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
