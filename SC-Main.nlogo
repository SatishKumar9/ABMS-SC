breed [consumers consumer]
breed [retailers retailer]
breed [houses house]
breed [distributors distributor]
breed [trucks truck]

globals
[
  acceleration
  num-cars-stopped
  is-day             ;; true if its day-time or false if isn't
  num-days-completed
  intersections      ;; agentset containing the patches that are intersections
  roads              ;; agentset containing the patches that are roads
]

retailers-own [
  my-store           ;; true if it's user's store and false if isn't
  stock              ;; present stock
  sold-stock         ;; total stock sold till tick
  purchased-stock    ;; total stock purchased till tick
  max-inventory      ;; max capacity
  waiting-list       ;; consumers waiting queue to leave the shop
  shoppers-list      ;; consumers waiting queue to shop
  max-occupancy
  ordered?           ;; true if ordered from a distributor or false if isn't
  num-consumers      ;; count of consumers at any time
]

consumers-own
[
  speed-limit
  speed              ;; the speed of the turtle
  wait-time          ;; the amount of time since the last time a turtle has moved
  go-to-store
  my-home            ;; the patch where they live
  goal               ;; where am I currently headed
  prev-patch
  roaming-time       ;; total travelling time
  temp-prev-patch
  stock-needed       ;; qty to purchase
  at-store?          ;; true if inside any store
]

trucks-own
[
  speed-limit
  speed              ;; the speed of the turtle
  wait-time          ;; the amount of time since the last time a turtle has moved
  go-to-store
  my-home            ;; the patch where they live
  goal               ;; where am I currently headed
  prev-patch
  temp-prev-patch
  stock              ;; qty carrying to be delivered
  on-road?           ;; true if travelling on-road
]

patches-own [
  intersection?      ;; true if the patch is at the intersection of two roads
]

distributors-own [
  pending-orders     ;; list of all orders yet to deliver
]

houses-own [
  max-roaming-time   ;; max shopping time
  max-people         ;; avg no. of consumers shop in a day
]


;;;;;;;;;;; Setup Procedures ;;;;;;;;;;

to setup
  clear-all-plots
  ask consumers [die]
  ask trucks [die]
  setup-globals
  setup-patches
  setup-retailers
  setup-distributors
  setup-houses

  set-default-shape consumers "car"
  set-default-shape trucks "truck"
  reset-ticks
end


to setup-houses
  ask houses[
    set max-roaming-time 2 * ticks-per-cycle
    set max-people avg-people-shopping
  ]
end


to setup-globals
  set num-cars-stopped 0
  ;; don't make acceleration 0.1 since we could get a rounding error and end up on a patch boundary
  set acceleration 0.099
  set is-day true
  set num-days-completed -1
end


to setup-patches
  ask patches [
    set intersection? false
  ]
  set roads patches with [ pcolor = white or pcolor = 109 ]
  set intersections roads with [
    check-neighbors4-pcolor >= 3
  ]
  setup-intersections
end


to-report check-neighbors4-pcolor
  report count neighbors4 with [ pcolor = white or pcolor = 109 ]
end


to setup-intersections
  ask intersections [
    set intersection? true
  ]
end


to setup-retailers
  ask retailers[
    set stock random-normal 1000 100
    set purchased-stock stock
    set sold-stock 0
    set max-inventory random-normal 6000 500
    set waiting-list []
    set shoppers-list []
    set max-occupancy random-normal 25 5
    set ordered? false
    set num-consumers 0
  ]

  ask retailers with [ my-store = true ] [
    set stock initial-stock
    set purchased-stock initial-stock
    set max-occupancy store-max-occupancy
  ]
end


to setup-distributors
  ask distributors[
    set pending-orders []
  ]
end


to setup-cars[ house-xcor house-ycor ]
  set speed 0
  set wait-time 0

  ; if the turtle is on a vertical road (rather than a horizontal one)
  ifelse (xcor = house-xcor)
  [ set heading 90 ]
  [ set heading 180 ]

end


;; Find a road patch without any turtles on it and place the turtle there.
to-report get-empty-road
  report one-of neighbors4 with [ (pcolor = white and not any? turtles-on self) or (pcolor = 109 and not any? turtles-on self) ]
end


;;;;;;;;;;; Go Procedures ;;;;;;;;;;;;;

to go
  set num-cars-stopped 0
  plot-profits
  ifelse is-day
  [ go-houses ]
  [ go-distributors ]
  go-retailers
  go-consumers
  go-trucks

  label-subject         ;; if we're watching a car, have it display its goal
  tick
end


to go-houses
  if ticks mod ticks-per-cycle = 0[
    ask houses with [ random-normal 10 2 < spawn-prob * 10 and max-people > 0 ]
    [
      set max-people max-people - 1
      spawn-consumer xcor ycor
    ]
  ]
end


to go-distributors
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
          set-car-color
          record-data
          set-speed
        ]
      ]
    ]
  ]
end


to go-retailers
  ask retailers [
    if not ordered? and stock < 100 [                          ;; order when stock is below a threshold
      let my-distributor one-of distributors in-radius 100
      let store-value self
      let stock-ordered 700
      hatch-trucks 1 [
        set xcor [pxcor] of my-distributor
        set ycor [pycor] of my-distributor
        set color magenta + 1
        set stock stock-ordered
        set prev-patch nobody
        set temp-prev-patch nobody
        set my-home my-distributor
        set go-to-store store-value
        set goal go-to-store
        set on-road? false
      ]
      set ordered? true
    ]
    if length shoppers-list > 0 [shopping]
    if length waiting-list > 0 [get-car-on-road]
  ]
end


to go-consumers
  ask consumers [
    if goal = my-home and (member? patch-here [ neighbors4 ] of my-home) [
      if stock-needed > 0 and is-day [
        ask my-home [
          set max-roaming-time max-roaming-time + 10
        ]
      ]
      die
    ]

    if goal = go-to-store and (member? patch-here [ neighbors4 ] of go-to-store) [
      reached-store
   ]

    if at-store? = false[
      set roaming-time roaming-time + 1
      if roaming-time >= [max-roaming-time] of my-home [
        set goal my-home
      ]
      travel
    ]
  ]
end


to go-trucks
  ask trucks with [ on-road? ] [
    if goal = my-home and (member? patch-here [ neighbors4 ] of my-home) [
      die
    ]

    if goal = go-to-store and (member? patch-here [ neighbors4 ] of go-to-store) [
      let stock-asked stock
      ask go-to-store[
        set purchased-stock purchased-stock + stock-asked
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
end


to reached-store
  ifelse length [waiting-list] of go-to-store + length [shoppers-list] of go-to-store < [max-occupancy] of go-to-store and [stock] of go-to-store > 0
  [
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


to spawn-consumer[house-xcor house-ycor]
  let place-at get-empty-road
  if place-at != nobody
  [
    hatch-consumers 1 [
      set xcor [pxcor] of place-at
      set ycor [pycor] of place-at
      set stock-needed random-normal 5 2
      set at-store? false
      set prev-patch nobody
      set temp-prev-patch nobody
      setup-cars house-xcor house-ycor
      set-car-color ;; slower turtles are blue, faster ones are colored cyan
      record-data
      set roaming-time 0
      set my-home one-of houses with [xcor = house-xcor and ycor = house-ycor]
      set go-to-store one-of retailers in-radius 100
      set goal go-to-store
      set-speed
    ]
  ]
end


to shopping
  let agent first shoppers-list
  if agent != nobody[
    ifelse stock >= [stock-needed] of agent
    [
      set stock stock - [stock-needed] of agent
      set sold-stock sold-stock + [stock-needed] of agent
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
      set sold-stock sold-stock + stock
      set stock 0
    ]
  ]
  set num-consumers num-consumers + 1
  set waiting-list lput agent waiting-list
  set shoppers-list but-first shoppers-list
end


to get-car-on-road
  let place-at get-empty-road
  if place-at != nobody
  [
    let agent first waiting-list
    set waiting-list but-first waiting-list
    if (agent != nobody) [
      ask agent [
        set xcor [pxcor] of place-at
        set ycor [pycor] of place-at
        set at-store? false
        set speed 0
        set prev-patch nobody
        set temp-prev-patch nobody
      ]
    ]
  ]
end


to travel
  face next-patch ;; car heads towards its goal
  set-speed
  set temp-prev-patch patch-here
  fd speed
  if patch-here != temp-prev-patch [ set prev-patch temp-prev-patch ]
  record-data
  set-car-color
end


to-report next-patch
  ;; CHOICES is an agentset of the candidate patches that the car can move to (white patches are roads)
  let choices neighbors with [ pcolor = white or pcolor = 109 ]
  if prev-patch != nobody and member? prev-patch choices
  [
    let prev-xcor [pxcor] of prev-patch
    let prev-ycor [pycor] of prev-patch
    set choices choices with [ remove-prev-patch prev-xcor prev-ycor ]
  ]
  let choice min-one-of choices [ distance [ goal ] of myself ]
  report choice
end


to-report remove-prev-patch[prev-xcor prev-ycor]
  if pxcor = prev-xcor and pycor = prev-ycor[report false]
  report true
end


;; set the speed variable of the turtle to an appropriate value (not exceeding the
;; speed limit) based on whether there are turtles on the patch in front of the turtle
to set-speed
  let consumers-ahead consumers-on  patch-ahead 0.16
  let trucks-ahead  trucks-on patch-ahead 0.16

  set consumers-ahead consumers-ahead with [ in-direction heading [heading] of myself]
  set trucks-ahead trucks-ahead with [ in-direction heading [heading] of myself]

  ifelse any? consumers-ahead or any? trucks-ahead
  [
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
  ][
    speed-up
  ]
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


to slow-down
  ifelse speed <= 0 or speed - acceleration < 0
    [ set speed 0 ]
    [ set speed speed - acceleration ]
end


to speed-up
  if pcolor = white [
    set speed-limit city-speed-limit
  ]
  if pcolor = 109 [
    set speed-limit highway-speed-limit
  ]
  ifelse speed > speed-limit or speed + acceleration > speed-limit
    [ set speed speed-limit ]
    [ set speed speed + acceleration ]
end


to set-car-color
  if pcolor = white [
    set speed-limit city-speed-limit
  ]
  if pcolor = 109 [
    set speed-limit highway-speed-limit
  ]
  ifelse speed < (speed-limit / 2)
    [ set color blue ]
    [ set color cyan + 2 ]
end


;;;;;;;;;;  Plot Procedures ;;;;;;;;;;;;;

to record-data
  ifelse speed = 0 [
    set num-cars-stopped num-cars-stopped + 1
    set wait-time wait-time + 1
  ]
  [ set wait-time 0 ]
end


to plot-profits
  if ticks != 0 and ticks mod 720 = 0 [
    ifelse is-day
    [
      set is-day false
      set num-days-completed num-days-completed + 1
      ask retailers with [my-store = true]
      [
        set-current-plot "Number of Consumers"
        if num-days-completed mod 7 = 0 [
          clear-plot
        ]
        create-temporary-plot-pen "default"
        set-plot-pen-mode 1
        set-plot-pen-color black
        plotxy num-days-completed mod 7 num-consumers
        set num-consumers 0
        set-current-plot "My Store Profit"
        create-temporary-plot-pen "default"
        set-plot-pen-color black
        plotxy num-days-completed ((sold-stock - (purchased-stock * wholesale-cost)) / (purchased-stock * wholesale-cost + 1)) * 100
      ]
      ask houses [ set max-people avg-people-shopping ]
      ask consumers [set goal my-home]
    ][
      set is-day true
    ]
  ]
end


;;;;;;;;;;;  Watch Prodcedures  ;;;;;;;;;;;

to watch-a-car
  stop-watching              ;; in case we were previously watching another car
  watch one-of consumers
  ask subject [
    inspect self
    set size 2               ;; make the watched car bigger to be able to see it
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


;;;;;;;;;; Import procedures ;;;;;;;;;;

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
745
60
1194
510
-1
-1
11.92
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
120.0

PLOT
30
335
246
510
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
"speed" 1.0 0 -7500403 true "" "if count consumers > 0 [ plot mean [speed] of consumers]"

BUTTON
130
35
215
68
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
30
35
114
68
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
30
145
175
178
city-speed-limit
city-speed-limit
0.1
1
0.6
0.1
1
NIL
HORIZONTAL

SLIDER
30
105
175
138
ticks-per-cycle
ticks-per-cycle
1
100
45.0
1
1
NIL
HORIZONTAL

BUTTON
30
285
175
318
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
180
285
325
318
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
925
515
1027
548
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
680
60
737
105
houses
count houses
17
1
11

MONITOR
625
60
682
105
retailers
count retailers
17
1
11

MONITOR
555
60
627
105
distributors
count distributors
17
1
11

MONITOR
555
290
627
335
Consumers
count consumers
17
1
11

BUTTON
230
35
307
68
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

PLOT
500
335
720
510
My Store Profit
Days
Profit
0.0
10.0
0.0
10.0
true
false
"" ""
PENS

SLIDER
225
145
397
178
wholesale-cost
wholesale-cost
0
1
0.65
0.01
1
NIL
HORIZONTAL

PLOT
275
335
485
510
Number of Consumers
Days in week
Consumers
0.0
10.0
0.0
10.0
true
false
"" ""
PENS

SLIDER
225
105
397
138
avg-people-shopping
avg-people-shopping
0
100
15.0
1
1
NIL
HORIZONTAL

MONITOR
500
290
557
335
Day
num-days-completed + 1
17
1
11

TEXTBOX
280
515
450
556
Number of consumers shopping at my store in a day
11
0.0
1

SLIDER
30
225
202
258
spawn-prob
spawn-prob
0
1
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
225
225
397
258
initial-stock
initial-stock
1
500
500.0
1
1
NIL
HORIZONTAL

SLIDER
225
185
397
218
store-max-occupancy
store-max-occupancy
1
100
25.0
1
1
NIL
HORIZONTAL

SLIDER
30
185
202
218
highway-speed-limit
highway-speed-limit
0.1
1
0.8
0.1
1
NIL
HORIZONTAL

TEXTBOX
275
85
425
103
My store setup\n
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

Profit maximization of a retailer in a Supply Chain Network simulates how the profit of a retailer changes over time by keeping into account the following factors
1. Shopping behaviour of consumers
2. Moving in traffic across a city layout (can be designed using another model named "Supply chain - layout")

This model simulates the day-night movement of consumers, by giving the goals, namely driving to-and-from a store. The agents in this model use goal-based cognition.

## HOW IT WORKS

The model simulates day-night simulation of a supply chain network, to capture the movement of consumers. Each time step(a tick) is assumed to be 1 minute.  Every 720 minutes (time steps) represents half-a-day. 

All the consumers try to shop at day time. During the remaining half of day, i.e. at night-time, remaining consumers head back to thier houses and only trucks move around to deliver products (if any) from distributors to retailers. This repeats for every 1440 minutes(time steps) to simulate days, weeks, and so on. 

During the day-time, consumers spawn at randomly across houses. They start moving towards their destination. At each time step, the cars(consumers) take their next step towards the goal they are trying to get to (store or house) and attempt to move forward at their current speed. If their current speed is less than the speed limit and there is no car directly in front of them, they accelerate. If there is a slower car in front of them, they match the speed of the slower car and decelerate. If there is a stationary car in front of them, they stop.

Each consumer has a house patch and a store patch. The cars will alternatively drive from house to store, store to house or to another store (if their stock requirement isn't met).

The retailers place an order from a distributor when their stocks reduce below a threshold and the delivery happens only at night.

## HOW TO USE IT

Import the city layout desgined using the "Supply chain - layout" model. (You can always change any existing layouts by importing it using the model). 

Press the SETUP button.

At this time, you may configure the slider values like ticks-per-cycle, spawn-prob, speed-limit and wholesale price cost of product. See below for details.

Start the simulation by pressing the GO button. You may continue to make changes to any slider values while the simulation is running.

### Buttons

IMPORT-LAYOUT -- imports an exixting layout created using "supply chain layout" model. 

SETUP -- All initial parameters are set for every agent.

GO -- runs the simulation indefinitely. Consumers spawn and travel from their houses to stores and back. Trucks spawn and travel, only when there's an order placed by a retailer.

WATCH A CAR -- selects a car to watch. Sets the car's label to its goal. Displays the car's house and the car's retail store it's headed to. Opens inspectors for the car being watched, it's house and store.

STOP WATCHING -- stops watching the current car being watched, resets it's labels of house and store.

### Sliders

SPEED-LIMIT -- sets the maximum speed for the consumers' cars while travelling.

TICKS-PER-CYCLE -- spawns a consumer with some probability (set by spawn-prob slider) for each cycle from every house. This allows you to increase or decrease the number of consumers that can spawn from a single house in a day.

SPAWN-PROB -- the probability of spawning a consumer in every cycle from every house.

WHOLESALE COST -- the price with which the retailer buys products from the distributor. (The selling price is set to 1 per product)


### Plots

STOPPED CARS -- displays the number of stopped cars over time.

AVERAGE SPEED OF CARS -- displays the average speed of cars over time.

AVERAGE WAIT TIME OF CARS -- displays the average time for which cars are stopped.

MY-STORE-PROFIT -- displays the profit for the user's store over time.


## THINGS TO NOTICE

## THINGS TO TRY

## EXTENDING THE MODEL

## RELATED MODELS

- "Supply chain layout" : model to design, import/export the city layout to simulate using this model.


## HOW TO CITE
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
