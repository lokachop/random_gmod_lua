-- exported with a helper script written by lokachop (Lokachop#5862)
LSCT=LSCT or {}
Surf3D=Surf3D or {}
Surf3D.Models=Surf3D.Models or {}
print("loading model: train")Surf3D.Models.train={}Surf3D.Models.train.Verts={Vector(-1,-1,2),Vector(-1,-1,-2),Vector(1,-1,2),Vector(1,-1,-2),Vector(-1,0.5,2),Vector(-1,0.5,-2),Vector(-0.5,1,-2),Vector(0.5,1,-2),Vector(1,0.5,-2),Vector(1,0.5,2),Vector(0.5,1,2),Vector(-0.5,1,2),Vector(0.3,-0.68,2.31),Vector(-0.3,-0.68,2.31),Vector(-0.3,0.34,2.31),Vector(0.3,0.34,2.31),Vector(0.39,0.81,2.31),Vector(-0.39,0.81,2.31),Vector(0.39,-0.57,2.38),Vector(0.39,-0.32,2.38),Vector(0.71,-0.57,2.38),Vector(0.71,-0.32,2.38),Vector(-0.71,-0.57,2.38),Vector(-0.71,-0.32,2.38),Vector(-0.39,-0.57,2.38),Vector(-0.39,-0.32,2.38),Vector(-0.79,0.42,2.31),Vector(-0.79,-0.76,2.31),Vector(0.79,0.42,2.31),Vector(0.79,-0.76,2.31),Vector(-0.83,0.68,1.77),Vector(-0.83,-0.97,1.77),Vector(0.83,0.68,1.77),Vector(0.83,-0.97,1.77),Vector(-0.2,-0.24,2.33),Vector(-0.2,0.26,2.33),Vector(0.2,-0.24,2.33),Vector(0.2,0.26,2.33),Vector(-1,-1,0),Vector(0,-1,2),Vector(1,-1,0),Vector(-1,0.5,0),Vector(-0.5,1,0),Vector(1,0.5,0),Vector(0.5,1,0),}Surf3D.Models.train.UVs = {{0.81,0.92},{0.75,0.98},{0.75,0.94},{0.91,0.84},{0.83,0.94},{0.94,0.86},{1,1},{0.88,1},{0.66,0.38},{0.83,0},{0.83,0.38},{0.64,0.97},{0.61,0.89},{0.66,0.92},{1,0.86},{0.88,0.86},{0.78,0.17},{1,0},{1,0.17},{0.23,1},{0,0.5},{0.23,0.5},{0.91,0.84},{1,1},{0.91,1},{0.98,0.95},{0.91,1},{0.92,0.95},{0.98,0.86},{1,0.84},{1,1},{0.92,0.86},{0.23,0.5},{0,1},{0,0.5},{1,1},{0.88,0.78},{1,0.78},{0.23,0.5},{0,0},{0.23,0},{0.75,0.34},{1,0},{1,0.34},{0.78,0},{0.89,0.38},{0.78,0.38},{0.7,0},{0.41,0.34},{0.41,0},{0.88,0.88},{1,1},{0.88,1},{0.7,0.34},{1,0},{1,0.34},{0.63,0},{0.81,0.19},{0.63,0.19},{1,0.38},{0.89,0},{1,0},{0.75,0.78},{0.88,1},{0.75,1},{0.75,0.88},{0.75,1},{1,0},{1,0.38},{0.81,1},{1,0.86},{1,1},{0.81,0},{1,0.19},{0.95,0.89},{1,0.86},{0.66,0},{0.59,0.94},{0.78,0},{0,1},{1,0.84},{0.23,1},{0,0.5},{0.75,0},{1,0.88},{0.81,0.86},{1,0},}Surf3D.Models.train.Indices = {{{29,1},{11,2},{17,3}},{{30,4},{10,5},{29,1}},{{40,6},{30,7},{28,8}},{{1,9},{42,10},{39,11}},{{12,12},{27,13},{18,14}},{{28,8},{5,15},{1,16}},{{32,17},{33,18},{31,19}},{{21,20},{20,21},{19,22}},{{12,12},{17,3},{11,2}},{{29,23},{18,24},{27,25}},{{15,26},{28,27},{14,28}},{{16,29},{30,4},{29,30}},{{15,26},{29,30},{27,31}},{{13,32},{28,27},{30,4}},{{25,33},{24,34},{23,35}},{{10,36},{45,37},{11,38}},{{37,39},{36,40},{35,41}},{{6,42},{4,43},{2,44}},{{9,45},{41,46},{4,47}},{{43,48},{8,49},{7,50}},{{42,51},{12,52},{43,53}},{{45,54},{12,55},{11,56}},{{4,57},{39,58},{2,59}},{{3,60},{44,61},{10,62}},{{8,63},{44,64},{9,65}},{{6,66},{43,53},{7,67}},{{39,11},{6,68},{2,69}},{{8,70},{6,71},{7,72}},{{41,73},{1,74},{39,58}},{{29,1},{10,5},{11,2}},{{30,4},{3,75},{10,5}},{{28,8},{1,16},{40,6}},{{40,6},{3,76},{30,7}},{{1,9},{5,77},{42,10}},{{12,12},{5,78},{27,13}},{{28,8},{27,31},{5,15}},{{32,17},{34,79},{33,18}},{{21,20},{22,80},{20,21}},{{12,12},{18,14},{17,3}},{{29,23},{17,81},{18,24}},{{15,26},{27,31},{28,27}},{{16,29},{13,32},{30,4}},{{15,26},{16,29},{29,30}},{{13,32},{14,28},{28,27}},{{25,33},{26,82},{24,34}},{{10,36},{44,64},{45,37}},{{37,39},{38,83},{36,40}},{{6,42},{9,84},{4,43}},{{9,45},{44,61},{41,46}},{{43,48},{45,54},{8,49}},{{42,51},{5,85},{12,52}},{{45,54},{43,48},{12,55}},{{4,57},{41,73},{39,58}},{{3,60},{41,46},{44,61}},{{8,63},{45,37},{44,64}},{{6,66},{42,51},{43,53}},{{39,11},{42,10},{6,68}},{{8,70},{9,86},{6,71}},{{41,73},{3,87},{1,74}},}