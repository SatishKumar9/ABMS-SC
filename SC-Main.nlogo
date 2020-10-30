globals
[
  acceleration             ;; the constant that controls how much a car speeds up or slows down by if
                           ;; it is to accelerate or decelerate
  num-cars-stopped         ;; the number of cars that are stopped during a single pass thru the go procedure

  ;; patch agentsets
  intersections ;; agentset containing the patches that are intersections
  roads         ;; agentset containing the patches that are roads
]

breed [consumers consumer]
breed [retailers retailer]
breed [houses house]
breed [distributors distributor]
breed [trucks truck]

retailers-own [
  my-store
  stock
  max-inventory
  waiting-list
  shoppers-list
  max-occupancy
  ordered?
]

consumers-own
[
  speed     ;; the speed of the turtle
  wait-time ;; the amount of time since the last time a turtle has moved
  go-to-store      ;; the patch where they work
  my-home     ;; the patch where they live
  goal      ;; where am I currently headed
  prev-patch
  temp-prev-patch
  stock-needed
  at-store?
]

trucks-own
[
  speed     ;; the speed of the turtle
  wait-time ;; the amount of time since the last time a turtle has moved
  go-to-store      ;; the patch where they work
  my-home     ;; the patch where they live
  goal      ;; where am I currently headed
  prev-patch
  temp-prev-patch
  stock
  on-road?
]

patches-own
[
  intersection?   ;; true if the patch is at the intersection of two roads
]

distributors-own
[
  pending-orders
]

to setup
  clear-all-plots
  ask consumers [die]
  ask trucks [die]
  setup-globals
  setup-patches  ;; ask the patches to draw themselves and set up a few variables
  setup-retailers
  setup-distributors

  set-default-shape consumers "car"
  set-default-shape trucks "airplane"


  ;; Now create the cars and have each created car call the functions setup-cars and set-car-color

  reset-ticks
end

;; Initialize the global variables to appropriate values
to setup-globals
  set num-cars-stopped 0
  ;; don't make acceleration 0.1 since we could get a rounding error and end up on a patch boundary
  set acceleration 0.099
end

;; Make the patches have appropriate colors, set up the roads and intersections agentsets,
;; and initialize the traffic lights to one setting
to setup-patches
  ;; initialize the patch-owned variables and color the patches to a base-color
  ask patches [
    set intersection? false
  ]

  ;; initialize the global variables that hold patch agentsets
  set roads patches with [ pcolor = white ]
  set intersections roads with [
    check-neighbors4-pcolor = 4
  ]

  setup-intersections
end

to-report check-neighbors4-pcolor
  report count neighbors4 with [ pcolor = white ]
end

;; Give the intersections appropriate values for the intersection?, my-row, and my-column
;; patch variables.  Make all the traffic lights start off so that the lights are red
;; horizontally and green vertically.
to setup-intersections
  ask intersections [
    set intersection? true
  ]
end

to setup-retailers
  ask retailers[
    set stock random 100 + 100
    set max-inventory random 1000 + 500
    set waiting-list []
    set shoppers-list []
    set max-occupancy random 10 + 10
    set ordered? false
  ]
end

to setup-distributors
  ask distributors[
    set pending-orders []
  ]
end

;; Initialize the turtle variables to appropriate values and place the turtle on an empty road patch.
to setup-cars[ house-xcor house-ycor ]  ;; turtle procedure
  set speed 0
  set wait-time 0

  ; if the turtle is on a vertical road (rather than a horizontal one)
  ifelse (xcor = house-xcor)
  [ set heading 90 ]
  [ set heading 180 ]

end

;; Find a road patch without any turtles on it and place the turtle there.
to-report get-empty-road  ;; turtle procedure
  report one-of neighbors4 with [ pcolor = white and not any? turtles-on self ]
end


;; Run the simulation
to go

  if ticks mod ticks-per-cycle = 0
  [
    ask houses with [ random 10 < spawn-prob * 10 ][ spawn-consumer xcor ycor ]
  ]


  ;; have the intersections change their color
  set num-cars-stopped 0

  ;; set the cars’ speed, move them forward their speed, record data for plotting,
  ;; and set the color of the cars to an appropriate color based on their speed

  ask distributors [
    let place-at get-empty-road
    if place-at != nobody
    [
      let pending-truck one-of trucks-here
      if pending-truck != nobody[
        ask pending-truck [
          setup-cars xcor ycor
          set xcor [pxcor] of place-at
          set ycor [pycor] of place-at
          set on-road? true
          set-car-color ;; slower turtles are blue, faster ones are colored cyan
          record-data
          set-speed
        ]
      ]
    ]
  ]

  ask trucks with [ on-road? ] [

    if goal = my-home and (member? patch-here [ neighbors4 ] of my-home) [
      die
    ]

    if goal = go-to-store and (member? patch-here [ neighbors4 ] of go-to-store) [
      let stock-asked stock
      ask go-to-store[
        set stock stock + stock-asked
        set ordered? false
      ]
      set stock 0
      set goal my-home
      set speed 0
      set prev-patch nobody
      set temp-prev-patch nobody
    ]

    travel
  ]

  ask retailers [
    if not ordered? and stock < 50[
      let my-distributor one-of distributors in-radius 100
      let store-value self
      let stock-ordered 500
      hatch-trucks 1 [
        set xcor [pxcor] of my-distributor
        set ycor [pycor] of my-distributor
        set stock stock-ordered
        set prev-patch nobody
        set temp-prev-patch nobody
        set my-home my-distributor
        ;; choose at random a location for work, make sure work is not located at same location as house
        set go-to-store store-value
        set goal go-to-store
        set on-road? false
      ]
      set ordered? true
    ]
    if length shoppers-list > 0[shopping]
    if length waiting-list > 0[get-car-on-road]

  ]

  ask consumers [
    if goal = my-home and (member? patch-here [ neighbors4 ] of my-home) [
      die
    ]

    if goal = go-to-store and (member? patch-here [ neighbors4 ] of go-to-store) [
      reached-store
   ]

    if at-store? = false[ travel ]

  ]
  label-subject ;; if we're watching a car, have it display its goal
  tick

end

to reached-store
  ifelse length [waiting-list] of go-to-store + length [shoppers-list] of go-to-store < [max-occupancy] of go-to-store and [stock] of go-to-store > 0 [
    set xcor [xcor] of go-to-store
    set ycor [ycor] of go-to-store
    let current self
    ask go-to-store[
      set shoppers-list lput current shoppers-list
    ]
    set at-store? true
    set goal my-home
  ][
    let available-store retailers in-radius 100
    let remove-store go-to-store
    set available-store available-store with [ self != remove-store ]
    set go-to-store one-of available-store
    set goal go-to-store
  ]

end

to shopping
  let agent first shoppers-list
  ifelse stock >= [stock-needed] of agent
  [
    set stock stock - [stock-needed] of agent
    ask agent [
      set stock-needed 0
    ]
  ][
    let current-stock stock
    ask agent [
      set stock-needed stock-needed - current-stock
      let available-store retailers in-radius 100
      let remove-store go-to-store
      set available-store available-store with [ self != remove-store ]
      set go-to-store one-of available-store
      set goal go-to-store
    ]
    set stock 0

  ]
  set waiting-list lput agent waiting-list
  set shoppers-list but-first shoppers-list
end

to get-car-on-road
  let place-at get-empty-road
  if place-at != nobody
  [
    let agent first waiting-list
    set waiting-list but-first waiting-list
    ;        let go-to-xcor [pxcor] of place-at
    ;        let go-to-ycor [pycor] of place-at
    ask agent [
      set xcor [pxcor] of place-at
      set ycor [pycor] of place-at
      set at-store? false
      set speed 0
      set prev-patch nobody
      set temp-prev-patch nobody
    ]
  ]
end

to travel
  face next-patch ;; car heads towards its goal
  set-speed
  set temp-prev-patch patch-here
  fd speed
  if patch-here != temp-prev-patch[ set prev-patch temp-prev-patch ]
  record-data     ;; record data for plotting
  set-car-color   ;; set color to indicate speed
end


to spawn-consumer[house-xcor house-ycor]
  let place-at get-empty-road
  if place-at != nobody
  [
    hatch-consumers 1 [
      set xcor [pxcor] of place-at
      set ycor [pycor] of place-at
      set stock-needed random 5 + 1
      set at-store? false
      set prev-patch nobody
      set temp-prev-patch nobody
      setup-cars house-xcor house-ycor
      set-car-color ;; slower turtles are blue, faster ones are colored cyan
      record-data
      ;; choose at random a location for the house
      set my-home one-of houses with [xcor = house-xcor and ycor = house-ycor]
      ;; choose at random a location for work, make sure work is not located at same location as house
      set go-to-store one-of retailers in-radius 100
      set goal go-to-store
      set-speed
    ]
  ]

end

;; set the speed variable of the turtle to an appropriate value (not exceeding the
;; speed limit) based on whether there are turtles on the patch in front of the turtle
to set-speed  ;; turtle procedure
  ;; get the turtles on the patch in front of the turtle
  let consumers-ahead consumers-on  patch-ahead 1
  let trucks-ahead  trucks-on patch-ahead 1
  set consumers-ahead consumers-ahead with [ in-direction heading [heading] of myself]
  set trucks-ahead trucks-ahead with [ in-direction heading [heading] of myself]
  ;; if there are turtles in front of the turtle, slow down
  ;; otherwise, speed up
  ifelse any? consumers-ahead or any? trucks-ahead [
    let change-speed []
    if count trucks-ahead > 0 [
      let min-truck-speed [speed] of min-one-of trucks-ahead [speed]
      set change-speed lput min-truck-speed change-speed
    ]
    if count consumers-ahead > 0 [
       let min-consumer-speed [speed] of min-one-of consumers-ahead [speed]
      set change-speed lput min-consumer-speed change-speed
    ]

    set speed min change-speed


      slow-down
  ]
  [ speed-up ]
end

to-report in-direction[near-car-heading car-heading]
  let diff 0
  if car-heading >= 0 and car-heading < diff[
    if near-car-heading >= 0 and near-car-heading < diff[report true]
    if near-car-heading > (360 - diff)  and near-car-heading <= 360[report true]
  ]
  if car-heading > (360 - diff)  and car-heading <= 360[
    if near-car-heading >= 0 and near-car-heading < diff [report true]
    if near-car-heading > (360 - diff)  and near-car-heading <= 360[report true]
  ]
  if abs (near-car-heading - car-heading) < diff [report true]
  report false
end

;; decrease the speed of the car
to slow-down  ;; turtle procedure
  ifelse speed <= 0
    [ set speed 0 ]
    [ set speed speed - acceleration ]
end

;; increase the speed of the car
to speed-up  ;; turtle procedure
  ifelse speed > speed-limit
    [ set speed speed-limit ]
    [ set speed speed + acceleration ]
end

;; set the color of the car to a different color based on how fast the car is moving
to set-car-color  ;; turtle procedure
  ifelse speed < (speed-limit / 2)
    [ set color blue ]
    [ set color cyan - 2 ]
end

;; keep track of the number of stopped cars and the amount of time a car has been stopped
;; if its speed is 0
to record-data  ;; turtle procedure
  ifelse speed = 0 [
    set num-cars-stopped num-cars-stopped + 1
    set wait-time wait-time + 1
  ]
  [ set wait-time 0 ]
end



;; establish goal of driver (house or work) and move to next patch along the way
to-report next-patch


  ;; CHOICES is an agentset of the candidate patches that the car can
  ;; move to (white patches are roads, green and red patches are lights)
  let choices neighbors with [ pcolor = white ]
  if prev-patch != nobody and member? prev-patch choices [

    let prev-xcor [pxcor] of prev-patch
    let prev-ycor [pycor] of prev-patch
    set choices choices with [ remove-prev-patch prev-xcor prev-ycor  ]

  ]

  let choice min-one-of choices [ distance [ goal ] of myself ]

  report choice
end

to-report remove-prev-patch[prev-xcor prev-ycor]
  if pxcor = prev-xcor and pycor = prev-ycor[report false]
  report true
end

to watch-a-car
  stop-watching ;; in case we were previously watching another car
  watch one-of consumers
  ask subject [

    inspect self
    set size 2 ;; make the watched car bigger to be able to see it

    ask my-home [
      set plabel "house"
      inspect self
    ]
    ask go-to-store [
      set plabel "go-to-store"
      inspect self
    ]
    set label [ plabel ] of goal ;; car displays its goal
  ]
end

to stop-watching
  ;; reset the house and work patches from previously watched car(s) to the background color
  ask houses [
    stop-inspecting self
    set plabel ""
  ]

  ask retailers [
    stop-inspecting self
    set plabel ""
  ]
  ;; make sure we close all turtle inspectors that may have been opened
  ask consumers [
    set label ""
    stop-inspecting self
  ]
  reset-perspective
end

to label-subject
  if subject != nobody [
    ask subject [
      if goal = my-home [ set label "house" ]
      if goal = go-to-store [ set label "go-to-store" ]
    ]
  ]
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

; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
900
15
1493
609
-1
-1
15.811
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

PLOT
465
255
683
430
Average Wait Time of Cars
Time
Average Wait
0.0
100.0
0.0
5.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [wait-time] of consumers "

PLOT
240
255
456
430
Average Speed of Cars
Time
Average Speed
0.0
100.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [speed] of consumers"

SLIDER
15
135
210
168
spawn-prob
spawn-prob
0
1
0.3
0.1
1
NIL
HORIZONTAL

PLOT
17
254
231
429
Stopped Cars
Time
Stopped Cars
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot num-cars-stopped"

BUTTON
230
10
315
43
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
130
10
214
43
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
15
90
160
123
speed-limit
speed-limit
0.1
1
0.8
0.1
1
NIL
HORIZONTAL

SLIDER
15
55
160
88
ticks-per-cycle
ticks-per-cycle
1
100
10.0
1
1
NIL
HORIZONTAL

BUTTON
15
185
160
218
watch a car
watch-a-car
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
165
185
310
218
stop watching
stop-watching
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
15
10
117
43
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
500
10
557
55
houses
count houses
17
1
11

MONITOR
420
10
477
55
retailers
count retailers
17
1
11

MONITOR
330
10
402
55
distributors
count distributors
17
1
11

MONITOR
575
10
647
55
consumers
count consumers
17
1
11

BUTTON
235
60
312
93
go-once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

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
