extensions [gis]
globals [yap areas poplist mos nbleedh Shg Ehg Ihg Rhg Smg Emg Img Shx Ehx Ihx Rhx Smx Emx Imx Shb Ehb Ihb Rhb Smb Emb Imb nIh Bh Bm pbleedm pbleedh mospop mosspread mosbite x y z popspread distm disth Ah Ch Am mosdeath]
patches-own [landtype Sh Eh Ih Rh Sm Em Im hpop mpop area popc]
breed [settlements settlement]

to setup
  clear-all
  ;set-perameters ;activate for manual use
  create-nodes
end

to rerun
  set-bleed ;calculates proportion of humans and moquitos leaving a patch every tick given radial exponential distribution and mean diatance migrated disth and distm
  clear-patches
  clear-plot
  reset-ticks
  set areas gis:load-dataset "Yap municipalities V4.asc"
  set yap gis:load-dataset "Yap land v2.asc"
  gis:apply-raster yap landtype
  gis:apply-raster areas area
  ask patches with [pxcor = 156] [set landtype 0
    set area 0]
  set-pop ;populating patches with humans an mosquitos
  set-colour ;visualises various patch variables (for manual use)
  ask patches [if Sh >= 0 [set Shg Shg + Sh
      set Ehg Ehg + Eh
      set Ihg Ihg + Ih
      set Rhg Rhg + Rh
      set Smg Smg + Sm
      set Emg Emg + Em
      set Img Img + Im]] ;summed patch variables for R and graphs
end

to go
  ask patches [set mpop Sm + Em + Im
    set hpop Sh + Eh + Ih + Rh]
  infect ;changing states of mosquitoes and humans
  mospawn ;death and spawning of mosquitos
  nodebleed ;exhange of humans between nodes (settlements)
  hbleed ;exhange of humans between nearby patches
  mbleed ;exhange of mosquitos between nearby patches
  set-colour
  set Shg 0
  set Ehg 0
  set Ihg 0
  set Rhg 0
  set Smg 0
  set Emg 0
  set Img 0
  ask patches [if Sh >= 0 [set Shg Shg + Sh
      set Ehg Ehg + Eh
      set Ihg Ihg + Ih
      set Rhg Rhg + Rh
      set Smg Smg + Sm
      set Emg Emg + Em
      set Img Img + Im]]
  tick
end

to set-perameters
  set Bm random-float 0.5 ;chance of a bite causing m to h transmission
  set Bh random-float 0.5 ;chance of a bite causing m to h transmission
  set mospop (random 96) + 12 ;mean poulation of mosquitos in urban builtup
  set mosspread (random-float 8) + 2 ;govens mpop in non urban patches
  set popspread (random 16) + 5 ;governs human population distribution
  set Ah (random-float 0.095) + 0.132 ;reciprocal of mean human uninfectious incubation period
  set Ch (random-float 0.734) + 0.174 ;reciprocal of mean human infectious period
  set distm (random-float 0.6) + 0.26 ;mean dispersion of mosquito in 1 day
  set disth (random-float 0.5) + 0.5 ;mean dispersion of human in 1 day
  set Am (random-float 0.167) + 0.083 ;reciprocal of mean mosquito uninfectious incubation period
  set mosdeath (random-float 0.251) + 0.09 ;reciprocal of mean mosquito lifelime
  set mosbite (random-float 13) + 2 ;mean number of bites a mosquitos will make in a tick
end

to set-pop
  ask patches [if area = 0 [set area 15]]
  set poplist n-values 15 [0]
  set poplist replace-item 14 poplist 1
  foreach [1 2 3 7 8 9 11 12 13 14][ask patches[if area = ? [set poplist replace-item (? - 1) poplist ((item (? - 1) poplist) + 1)
        set popc popc + 1
        if member? landtype [3 5 12 13] [set poplist replace-item (? - 1) poplist ((item (? - 1) poplist) + popspread)
          set popc popc + popspread]
        if landtype = 13 [set poplist replace-item (? - 1) poplist ((item (? - 1) poplist) + popspread)
          set popc popc + popspread]]]]
  ask patches[set Sh poisson(popc * (item (area - 1) [270 1022 641 0 0 0 1192 2023 124 0 730 551 236 596 0]) / (item (area - 1) poplist)) ;list of yap municipality populations (from census)
    if member? landtype [1 2 4 6 7 8 9 10 11 14] [set Sm round(mospop / (mosspread ^ 2))
      set x x + 1]
    if member? landtype [3 5 12] [set Sm round(mospop / mosspread)
      set y y + 1]
    if landtype = 13 [set Sm mospop
      set z z + 1]
    if area = 0 [set area 15
    set Sm 0]
    set mpop Sm + Em + Im
    set hpop Sh + Eh + Ih + Rh]
  ask patch 73 86 [set Ih 1]
end

to set-colour
  let cmap position patches-show ["municipality" "vegetation" "infected-humans" "infected-mosquitoes" "humans" "mosquitoes" "suceptable-humans" "recovered-humans"]
  ask patches [let clist (list area landtype Ih Im hpop mpop Sh Rh)
    set pcolor item cmap clist]
end

to create-nodes
  foreach n-values 17 [?] [let xc item ? [73 52 50 31 36 44 79 121 108 99 122 146 119 134 128 9 8]
    let yc item ? [83 80 66 61 88 111 116 115 93 84 100 117 177 167 192 22 2]
    ask patch xc yc [sprout 1
      set Sh Sh + 5]]
  ask turtles [set breed settlements]
  foreach n-values 22 [?] [let S1 item ? [0 1 4 5 1 2 3 15 2 0 0 6 6 7 7 8 8 7 7 12 12 13]
      let S2 item ? [1 4 5 6 2 3 15 16 15 6 5 7 8 8 10 10 9 11 12 13 14 14]
      ask settlement S1 [create-link-with settlement S2]]
end

to set-bleed
  ask patch 0 0 [let a 0
    let b 0
    let c 0
    let pat 0
    while [c < 100000] [set pat patch-at-heading-and-distance (random 360) (random-exponential (distm))
      if pat != self [set a a + 1]
      set pat patch-at-heading-and-distance (random 360) (random-exponential (disth))
      if pat != self [set b b + 1]
      set c c + 1]
    set pbleedm a / 100000
    set pbleedh b / 100000]
end


to infect
  set nIh 0
  ask patches [if hpop > 0 [let nobit mosbite / hpop
        let expos binom (Sh) (1 - ((1 - Bh) ^ (nobit * Im)))
        let devel binom (Eh) (Ah)
        let recov binom (Ih) (Ch)
        let exposm binom (Sm) (1 - ((1 - (Bm * Ih / hpop)) ^ mosbite))
        let develm binom (Em) (Am)
        set Sh Sh - expos
        set Eh Eh + expos - devel
        set Ih Ih + devel - recov
        set Rh Rh + recov
        set Sm Sm - exposm
        set Em Em + exposm - develm
        set Im Im + develm
        set nIh nIh + devel]]
end

to mospawn
  ask patches [let Smd binom (Sm) (mosdeath)
    let Emd binom (Em) (mosdeath)
    let Imd binom (Im) (mosdeath)
    set Sm Sm - Smd
    set Em Em - Emd
    set Im Im - Imd
    set mos mos + Smd + Emd + Imd]
  let mosx round(x * mos / (x + mosspread * y + (mosspread ^ 2) * z))
  let mosy round(y * mosspread * mos / (x + mosspread * y + (mosspread ^ 2) * z))
  let mosz round(z * (mosspread ^ 2) * mos / (x + mosspread * y + (mosspread ^ 2) * z))
  ask patches with [member? landtype [1 2 4 6 7 8 9 10 11 14]] [set Sm Sm + int(mos / (x + mosspread * y + (mosspread ^ 2) * z)) ;sparsely inhabited landtypes (eg secondary vegetation)
    set mosx mosx - int(mos / (x + mosspread * y + (mosspread ^ 2) * z))]
  while [mosx > 0] [ ask one-of patches with [member? landtype [1 2 4 6 7 8 9 10 11 14]] [set Sm Sm + 1
      set mosx mosx - 1]]
  ask patches with [member? landtype [3 5 12]] [set Sm Sm + int(mos * mosspread / (x + mosspread * y + (mosspread ^ 2) * z)) ;landtypes 3, 5, 12 are medium inhabited (eg agroforest)
    set mosy mosy - int(mos * mosspread / (x + mosspread * y + (mosspread ^ 2) * z))]
  while [mosy > 0] [ ask one-of patches with [member? landtype [3 5 12]] [set Sm Sm + 1
      set mosy mosy - 1]]
  ask patches with [landtype = 13] [set Sm Sm + int(mos * (mosspread ^ 2) / (x + mosspread * y + (mosspread ^ 2) * z)) ;landtype 13 is urban builtup
    set mosz mosz - int(mos * (mosspread ^ 2) / (x + mosspread * y + (mosspread ^ 2) * z))]
  while [mosz > 0] [ ask one-of patches with [landtype = 13] [set Sm Sm + 1
      set mosz mosz - 1]]
  set mos 0
  ask patches [set mpop Sm + Em + Im
    set hpop Sh + Eh + Ih + Rh]
end

to nodebleed
  ask links [ifelse [hpop] of end1 >= [hpop] of end2 [ask end2 [ask patch-here[set Shb binom (Sh) (pbleedh)
          set Ehb binom (Eh) (pbleedh)
          set Ihb binom (Ih) (pbleedh)
          set Rhb binom (Rh) (pbleedh)
          set nbleedh (Shb + Ehb + Ihb + Rhb)]]
      ask end1 [ask patch-here [let Shl n-values Sh [1]
          let Ehl n-values Eh [2]
          let Ihl n-values Ih [3]
          let Rhl n-values Rh [4]
          let hlist (sentence Shl Ehl Ihl Rhl)
          set hlist n-of nbleedh hlist
          set Shx filter [? = 1] hlist
          set Shx length Shx
          set Ehx filter [? = 2] hlist
          set Ehx length Ehx
          set Ihx filter [? = 3] hlist
          set Ihx length Ihx
          set Rhx filter [? = 4] hlist
          set Rhx length Rhx
          set Sh Sh + Shb - Shx
          set Eh Eh + Ehb - Ehx
          set Ih Ih + Ihb - Ihx
          set Rh Rh + Rhb - Rhx]]
      ask end2 [ask patch-here[set Sh Sh - Shb + Shx
          set Eh Eh - Ehb + Ehx
          set Ih Ih - Ihb + Ihx
          set Rh Rh - Rhb + Rhx]]]
      [ask end1 [ask patch-here[set Shb binom (Sh) (pbleedh)
          set Ehb binom (Eh) (pbleedh)
          set Ihb binom (Ih) (pbleedh)
          set Rhb binom (Rh) (pbleedh)
          set nbleedh (Shb + Ehb + Ihb + Rhb)]]
      ask end2 [ask patch-here [let Shl n-values Sh [1]
          let Ehl n-values Eh [2]
          let Ihl n-values Ih [3]
          let Rhl n-values Rh [4]
          let hlist (sentence Shl Ehl Ihl Rhl)
          set hlist n-of nbleedh hlist
          set Shx filter [? = 1] hlist
          set Shx length Shx
          set Ehx filter [? = 2] hlist
          set Ehx length Ehx
          set Ihx filter [? = 3] hlist
          set Ihx length Ihx
          set Rhx filter [? = 4] hlist
          set Rhx length Rhx
          set Sh Sh + Shb - Shx
          set Eh Eh + Ehb - Ehx
          set Ih Ih + Ihb - Ihx
          set Rh Rh + Rhb - Rhx]]
      ask end1 [ask patch-here[set Sh Sh - Shb + Shx
          set Eh Eh - Ehb + Ehx
          set Ih Ih - Ihb + Ihx
          set Rh Rh - Rhb + Rhx]]]]
end

to hbleed
  ask patches [if (hpop > 0) and area < 15 [set Shb binom (Sh) (pbleedh)
      set Ehb binom (Eh) (pbleedh)
      set Ihb binom (Ih) (pbleedh)
      set Rhb binom (Rh) (pbleedh)
      set nbleedh (Shb + Ehb + Ihb + Rhb)
      let swap 0
      let a 0
      let pat 0
      while [a = 0] [set pat patch-at-heading-and-distance (random 360) (random-exponential disth)
        if pat != nobody and pat != self [set a 1]]
      ask pat [if area < 15 and hpop >= nbleedh [let Shl n-values Sh [1]
          let Ehl n-values Eh [2]
          let Ihl n-values Ih [3]
          let Rhl n-values Rh [4]
          let hlist (sentence Shl Ehl Ihl Rhl)
          set hlist n-of nbleedh hlist
          set Shx filter [? = 1] hlist
          set Shx length Shx
          set Ehx filter [? = 2] hlist
          set Ehx length Ehx
          set Ihx filter [? = 3] hlist
          set Ihx length Ihx
          set Rhx filter [? = 4] hlist
          set Rhx length Rhx
          set Sh Sh + Shb - Shx
          set Eh Eh + Ehb - Ehx
          set Ih Ih + Ihb - Ihx
          set Rh Rh + Rhb - Rhx
          set swap 1]]
    if swap = 1 [set Sh Sh - Shb + Shx
      set Eh Eh - Ehb + Ehx
      set Ih Ih - Ihb + Ihx
      set Rh Rh - Rhb + Rhx]]]
end

to mbleed
  ask patches [if (mpop > 0) [set Smb binom (Sm) (pbleedm)
      set Emb binom (Em) (pbleedm)
      set Imb binom (Im) (pbleedm)
      set Sm Sm - Smb
      set Em Em - Emb
      set Im Im - Imb
      let a 0
      let pat 0
      let mov item landtype [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
      while [a = 0] [set pat patch-at-heading-and-distance (random 360) (random-exponential (distm * mov))
        if pat != nobody and pat != self [set a 1]]
      ask pat [set Sm Sm + Smb
        set Em Em + Emb
        set Im Im + Imb]]]
end

to-report poisson [lam]
  let p 1
  let k 0
  while [p > exp(-1 * lam)] [set p p * random-float 1
    set k k + 1]
  report k - 1
end

to-report binom [n q]
  report sum n-values n [ifelse-value (q > random-float 1) [1] [0]]
end
@#$#@#$#@
GRAPHICS-WINDOW
254
15
596
504
-1
-1
2.1013
1
10
1
1
1
0
0
0
1
0
157
0
217
1
1
1
ticks
30.0

BUTTON
24
37
87
70
NIL
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

BUTTON
24
70
87
103
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
628
10
1257
490
plot 1
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot Shg"
"pen-1" 1.0 0 -7500403 true "" "plot Ehg"
"pen-2" 1.0 0 -2674135 true "" "plot Ihg"

CHOOSER
6
169
179
214
patches-show
patches-show
"municipality" "vegetation" "infected-humans" "infected-mosquitoes" "humans" "mosquitoes" "suceptable-humans" "recovered-humans"
1

BUTTON
24
103
87
136
NIL
rerun
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
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
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
0
@#$#@#$#@
